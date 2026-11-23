-- luxury_core: Puente e Integración con ox_inventory
Inventory = {}

local hasOxInventory = GetResourceState('ox_inventory') == 'started'

-- Eventos de estado de recursos para detectar si ox_inventory se inicia o apaga en caliente
AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' then
        hasOxInventory = true
        print('^2[luxury_core]^7 Conexión con ox_inventory establecida con éxito.')
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == 'ox_inventory' then
        hasOxInventory = false
        print('^3[luxury_core]^7 ox_inventory se ha detenido.')
    end
end)

--- Añade un ítem al inventario del jugador
-- @param src number: Source del jugador
-- @param item string: Nombre del ítem
-- @param count number: Cantidad
-- @param metadata table|nil: Metadatos personalizados del ítem
-- @param slot number|nil: Slot específico (opcional)
-- @return boolean, string|nil
function Inventory.AddItem(src, item, count, metadata, slot)
    if not hasOxInventory then
        print(('[^1ERROR^7] ox_inventory no está activo para añadir %s x%d'):format(item, count))
        return false, 'inventory_not_ready'
    end

    count = tonumber(count) or 1
    if count <= 0 then return false, 'invalid_amount' end

    local success, response = exports.ox_inventory:AddItem(src, item, count, metadata, slot)
    return success, response
end

--- Retira un ítem del inventario del jugador
-- @param src number: Source del jugador
-- @param item string: Nombre del ítem
-- @param count number: Cantidad a remover
-- @param metadata table|nil: Metadatos para coincidencia estricta
-- @param slot number|nil: Slot específico
-- @return boolean, string|nil
function Inventory.RemoveItem(src, item, count, metadata, slot)
    if not hasOxInventory then
        return false, 'inventory_not_ready'
    end

    count = tonumber(count) or 1
    if count <= 0 then return false, 'invalid_amount' end

    local success = exports.ox_inventory:RemoveItem(src, item, count, metadata, slot)
    return success
end

--- Obtiene un ítem del inventario del jugador
-- @param src number: Source del jugador
-- @param item string: Nombre del ítem
-- @param metadata table|nil: Metadatos específicos
-- @return table|nil
function Inventory.GetItem(src, item, metadata)
    if not hasOxInventory then return nil end
    return exports.ox_inventory:GetItem(src, item, metadata)
end

--- Comprueba si el jugador tiene suficiente cantidad de un ítem
-- @param src number: Source del jugador
-- @param item string: Nombre del ítem
-- @param count number|nil: Cantidad requerida (default 1)
-- @return boolean
function Inventory.HasItem(src, item, count)
    if not hasOxInventory then return false end
    count = count or 1
    local itemData = exports.ox_inventory:GetItem(src, item)
    return itemData and (itemData.count or itemData.amount or 0) >= count
end

--- Comprueba si el jugador puede cargar un ítem sin superar el límite de peso
-- @param src number: Source del jugador
-- @param item string: Nombre del ítem
-- @param count number: Cantidad
-- @return boolean
function Inventory.CanCarryItem(src, item, count)
    if not hasOxInventory then return false end
    return exports.ox_inventory:CanCarryItem(src, item, count or 1)
end

--- Retorna todo el inventario del jugador
-- @param src number: Source del jugador
-- @return table|nil
function Inventory.GetInventory(src)
    if not hasOxInventory then return nil end
    return exports.ox_inventory:GetInventory(src)
end

--- Limpia por completo el inventario del jugador
-- @param src number: Source del jugador
-- @return boolean
function Inventory.ClearInventory(src)
    if not hasOxInventory then return false end
    return exports.ox_inventory:ClearInventory(src)
end

-- Exports del servidor para que cualquier recurso pueda interactuar con el inventario
exports('AddItem', Inventory.AddItem)
exports('RemoveItem', Inventory.RemoveItem)
exports('GetItem', Inventory.GetItem)
exports('HasItem', Inventory.HasItem)
exports('CanCarryItem', Inventory.CanCarryItem)
exports('GetInventory', Inventory.GetInventory)
exports('ClearInventory', Inventory.ClearInventory)
