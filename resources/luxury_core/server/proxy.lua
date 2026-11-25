-- luxury_core: Interfaz de Proxy y Tunnel del Servidor
Proxy = Proxy or {}
if not Proxy.addInterface then
    Proxy.addInterface = function(name, itf) end
end
Tunnel = Tunnel or {}
if not Tunnel.bindInterface then
    Tunnel.bindInterface = function(name, itf) end
end

local ServerInterface = {}

-- Métodos de Jugador y Core
ServerInterface.GetPlayer = function(src) return Core.Players[tonumber(src)] end
ServerInterface.GetPlayers = function() return Core.Players end
ServerInterface.GetPlayerByCitizenId = function(cid) return exports.luxury_core:GetPlayerByCitizenId(cid) end

-- Métodos de Economía
ServerInterface.AddMoney = function(src, account, amount)
    local p = Core.Players[tonumber(src)]
    return p and p:addMoney(account, amount) or false
end

ServerInterface.RemoveMoney = function(src, account, amount)
    local p = Core.Players[tonumber(src)]
    return p and p:removeMoney(account, amount) or false
end

ServerInterface.SetMoney = function(src, account, amount)
    local p = Core.Players[tonumber(src)]
    return p and p:setMoney(account, amount) or false
end

ServerInterface.GetMoney = function(src, account)
    local p = Core.Players[tonumber(src)]
    return p and p:getMoney(account) or 0
end

-- Métodos de Trabajo y Permisos
ServerInterface.SetJob = function(src, name, grade)
    local p = Core.Players[tonumber(src)]
    return p and p:setJob(name, grade) or false
end

ServerInterface.HasGroup = function(src, group)
    local p = Core.Players[tonumber(src)]
    return p and p:hasGroup(group) or false
end

-- Métodos de Inventario (ox_inventory)
ServerInterface.AddItem = function(src, item, count, metadata, slot)
    return Inventory.AddItem(tonumber(src), item, count, metadata, slot)
end

ServerInterface.RemoveItem = function(src, item, count, metadata, slot)
    return Inventory.RemoveItem(tonumber(src), item, count, metadata, slot)
end

ServerInterface.HasItem = function(src, item, count)
    return Inventory.HasItem(tonumber(src), item, count)
end

ServerInterface.GetItem = function(src, item, metadata)
    return Inventory.GetItem(tonumber(src), item, metadata)
end

ServerInterface.GetInventory = function(src)
    return Inventory.GetInventory(tonumber(src))
end

-- Métodos de Sociedades
ServerInterface.GetSocietyMoney = function(name) return Society.GetMoney(name) end
ServerInterface.AddSocietyMoney = function(name, amount) return Society.AddMoney(name, amount) end
ServerInterface.RemoveSocietyMoney = function(name, amount) return Society.RemoveMoney(name, amount) end

-- Métodos de Necesidades
ServerInterface.AddNeed = function(src, need, amount) return AddNeed(tonumber(src), need, amount) end
ServerInterface.RemoveNeed = function(src, need, amount) return RemoveNeed(tonumber(src), need, amount) end
ServerInterface.GetNeed = function(src, need) return GetNeed(tonumber(src), need) end

-- Métodos de Seguridad
ServerInterface.BanPlayer = function(src, reason) Security.BanPlayer(tonumber(src), reason) end

---------------------------------------------------------------------
-- Registro de Interfaces en Proxy (Servidor) y Tunnel Seguro (Cliente -> Servidor)
---------------------------------------------------------------------
Proxy.addInterface('luxury', ServerInterface)
Proxy.addInterface('luxury_core', ServerInterface)

-- Por seguridad, Tunnel solo expone consultas de solo lectura hacia clientes remotos.
-- Las mutaciones (dinero, trabajos, ítems, baneos) quedan restringidas a Proxy servidor.
local ClientTunnelSafeInterface = {
    GetMoney = ServerInterface.GetMoney,
    GetNeed = ServerInterface.GetNeed,
    GetSocietyMoney = ServerInterface.GetSocietyMoney
}

Tunnel.bindInterface('luxury', ClientTunnelSafeInterface)
Tunnel.bindInterface('luxury_core', ClientTunnelSafeInterface)

--- Despachador de Proxy para llamadas que vengan a través de exports desde otros recursos
exports('ProxyCall', function(interfaceName, methodName, ...)
    local iface = (interfaceName == 'luxury' or interfaceName == 'luxury_core') and ServerInterface or nil
    if iface and iface[methodName] then
        return iface[methodName](...)
    end
    error(('[^1PROXY ERROR^7] El método %s en la interfaz %s no existe'):format(tostring(methodName), tostring(interfaceName)))
end)

exports('GetProxy', function() return Proxy end)
exports('GetTunnel', function() return Tunnel end)
