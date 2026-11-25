-- luxury_garage: Lógica de Servidor - Garajes, Depósito y Llaves
-- Compatible con TODAS las versiones de ESX y Luxury Framework

local ESX = nil
local vehicleKeys = {} -- vehicleKeys[plate] = { [citizenid] = true }

-- Obtención segura de ESX (Compatible con todas las versiones)
local function getESX()
    local esxObj = nil
    TriggerEvent('esx:getSharedObject', function(obj) esxObj = obj end)
    if esxObj then return esxObj end

    pcall(function()
        if exports['es_extended'] then esxObj = exports['es_extended']:getSharedObject() end
    end)
    if esxObj then return esxObj end

    pcall(function()
        if exports['luxury_core'] then esxObj = exports['luxury_core']:GetESX() end
    end)
    return esxObj
end

CreateThread(function()
    while ESX == nil do
        ESX = getESX()
        if not ESX then Wait(250) end
    end
end)

--- Inicialización de Base de Datos Automática para Garajes
CreateThread(function()
    while not MySQL do Wait(100) end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_owned_vehicles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(60) NOT NULL,
            `plate` VARCHAR(12) NOT NULL UNIQUE,
            `vehicle` VARCHAR(50) NOT NULL,
            `mods` LONGTEXT DEFAULT NULL,
            `garage` VARCHAR(50) NOT NULL DEFAULT 'LegionSquare',
            `state` INT NOT NULL DEFAULT 1 COMMENT '1 = En Garaje, 0 = En Calle/Depósito, 2 = Incautado Policial',
            `fuel` INT NOT NULL DEFAULT 100,
            `engine` INT NOT NULL DEFAULT 1000,
            `body` INT NOT NULL DEFAULT 1000,
            `stored_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_veh_citizenid` (`citizenid`),
            INDEX `idx_veh_plate` (`plate`),
            INDEX `idx_veh_garage` (`garage`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print('^2[luxury_garage]^7 Base de datos de garajes y vehículos propios instalada y verificada automáticamente.')
end)

--- Obtener el identificador del jugador (citizenid / license)
local function getPlayerIdentifier(src)
    if not ESX then return tostring(src) end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return tostring(src) end
    return xPlayer.identifier or xPlayer.citizenid or tostring(src)
end

--- Notificar al jugador usando luxury_notify si existe o xPlayer
local function notifyPlayer(src, title, msg, nType)
    if exports['luxury_notify'] then
        exports['luxury_notify']:Alert(title, msg, 4000, nType)
    else
        TriggerClientEvent('esx:showNotification', src, msg)
    end
end

--- Obtener vehículos del jugador para el menú
RegisterNetEvent('luxury_garage:server:requestVehicles', function(garageId, isImpound)
    local src = source
    local cid = getPlayerIdentifier(src)

    local query = [[
        SELECT plate, vehicle, garage, state, fuel, engine, body, mods
        FROM luxury_owned_vehicles
        WHERE citizenid = ?
    ]]
    local params = { cid }

    if not isImpound then
        -- En garaje normal se muestran los que pertenecen a ese garaje o están dentro
        query = query .. ' AND (garage = ? OR state = 1)'
        table.insert(params, garageId)
    end

    local rows = MySQL.query.await(query, params) or {}
    local vehicles = {}

    for _, row in ipairs(rows) do
        table.insert(vehicles, {
            plate = row.plate,
            model = row.vehicle,
            garage = row.garage,
            state = row.state,
            fuel = tonumber(row.fuel) or 100,
            engine = math.floor((tonumber(row.engine) or 1000) / 10),
            body = math.floor((tonumber(row.body) or 1000) / 10),
            mods = (type(row.mods) == 'string' and json.decode(row.mods)) or row.mods or {}
        })
    end

    TriggerClientEvent('luxury_garage:client:openMenu', src, {
        garageId = garageId,
        garageLabel = (isImpound and Config.Impounds[garageId] and Config.Impounds[garageId].label) or (Config.Garages[garageId] and Config.Garages[garageId].label) or tostring(garageId),
        isImpound = isImpound,
        fee = isImpound and (Config.Impounds[garageId].fee or Config.ImpoundFee) or 0,
        vehicles = vehicles
    })
end)

--- Sacar vehículo del garaje
RegisterNetEvent('luxury_garage:server:spawnVehicle', function(plate, garageId)
    local src = source
    local cid = getPlayerIdentifier(src)

    local row = MySQL.single.await([[
        SELECT plate, vehicle, mods, fuel, engine, body, state
        FROM luxury_owned_vehicles
        WHERE plate = ? AND citizenid = ?
    ]], { plate, cid })

    if not row then
        notifyPlayer(src, 'Error', 'No eres el propietario de este vehículo.', 'error')
        return
    end

    if row.state == 0 then
        notifyPlayer(src, 'Aviso', 'Este vehículo ya se encuentra fuera del garaje o en el depósito.', 'warning')
        return
    end

    -- Actualizar estado a fuera (0)
    MySQL.update([[
        UPDATE luxury_owned_vehicles SET state = 0 WHERE plate = ?
    ]], { plate })

    -- Otorgar llaves al dueño
    vehicleKeys[plate] = vehicleKeys[plate] or {}
    vehicleKeys[plate][cid] = true

    local mods = (type(row.mods) == 'string' and json.decode(row.mods)) or row.mods or {}
    local garageCfg = Config.Garages[garageId] or Config.Garages['LegionSquare']

    TriggerClientEvent('luxury_garage:client:spawnVehicle', src, {
        model = row.vehicle,
        plate = row.plate,
        mods = mods,
        fuel = row.fuel,
        engine = row.engine,
        body = row.body,
        spawn = garageCfg.spawn
    })

    notifyPlayer(src, 'Garaje', 'Vehículo extraído con éxito.', 'success')
end)

--- Guardar vehículo en el garaje
RegisterNetEvent('luxury_garage:server:storeVehicle', function(plate, garageId, stats)
    local src = source
    local cid = getPlayerIdentifier(src)

    local row = MySQL.single.await([[
        SELECT id FROM luxury_owned_vehicles WHERE plate = ? AND citizenid = ?
    ]], { plate, cid })

    if not row then
        notifyPlayer(src, 'Error', 'Este vehículo no te pertenece.', 'error')
        return
    end

    local engine = math.max(0, math.min(1000, tonumber(stats and stats.engine) or 1000))
    local body = math.max(0, math.min(1000, tonumber(stats and stats.body) or 1000))
    local fuel = math.max(0, math.min(100, tonumber(stats and stats.fuel) or 100))
    local modsStr = stats and stats.mods and json.encode(stats.mods) or nil

    if modsStr then
        MySQL.update([[
            UPDATE luxury_owned_vehicles
            SET state = 1, garage = ?, engine = ?, body = ?, fuel = ?, mods = ?
            WHERE plate = ?
        ]], { garageId, engine, body, fuel, modsStr, plate })
    else
        MySQL.update([[
            UPDATE luxury_owned_vehicles
            SET state = 1, garage = ?, engine = ?, body = ?, fuel = ?
            WHERE plate = ?
        ]], { garageId, engine, body, fuel, plate })
    end

    TriggerClientEvent('luxury_garage:client:vehicleStored', src)
    notifyPlayer(src, 'Garaje', 'Vehículo estacionado y guardado en ' .. (Config.Garages[garageId] and Config.Garages[garageId].label or garageId), 'success')
end)

--- Pagar rescate en el Depósito (Impound)
RegisterNetEvent('luxury_garage:server:payImpound', function(plate, impoundId)
    local src = source
    if not ESX then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local cid = getPlayerIdentifier(src)
    local fee = Config.Impounds[impoundId] and Config.Impounds[impoundId].fee or Config.ImpoundFee

    local bankMoney = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0
    if bankMoney < fee then
        notifyPlayer(src, 'Depósito', 'No dispones de saldo suficiente en el banco para pagar la tasa de $' .. fee, 'error')
        return
    end

    local row = MySQL.single.await([[
        SELECT plate, vehicle, mods, fuel, engine, body FROM luxury_owned_vehicles WHERE plate = ? AND citizenid = ?
    ]], { plate, cid })

    if not row then
        notifyPlayer(src, 'Error', 'El vehículo no te pertenece.', 'error')
        return
    end

    xPlayer.removeAccountMoney('bank', fee)

    MySQL.update([[
        UPDATE luxury_owned_vehicles SET state = 0 WHERE plate = ?
    ]], { plate })

    -- Otorgar llaves
    vehicleKeys[plate] = vehicleKeys[plate] or {}
    vehicleKeys[plate][cid] = true

    local mods = (type(row.mods) == 'string' and json.decode(row.mods)) or row.mods or {}
    local impCfg = Config.Impounds[impoundId] or Config.Impounds['CityImpound']

    TriggerClientEvent('luxury_garage:client:spawnVehicle', src, {
        model = row.vehicle,
        plate = row.plate,
        mods = mods,
        fuel = row.fuel,
        engine = row.engine,
        body = row.body,
        spawn = impCfg.spawn
    })

    notifyPlayer(src, 'Depósito', 'Tasa de $' .. fee .. ' abonada. Tu vehículo ha sido liberado.', 'success')
end)

--- Sistema de Llaves de Vehículo
RegisterNetEvent('luxury_garage:server:toggleLock', function(plate, netId)
    local src = source
    local cid = getPlayerIdentifier(src)

    -- Comprobar si el jugador tiene llaves
    local hasKey = (vehicleKeys[plate] and vehicleKeys[plate][cid])
    if not hasKey then
        -- Comprobar si es el dueño registrado
        local row = MySQL.single.await('SELECT id FROM luxury_owned_vehicles WHERE plate = ? AND citizenid = ?', { plate, cid })
        if row then
            vehicleKeys[plate] = vehicleKeys[plate] or {}
            vehicleKeys[plate][cid] = true
            hasKey = true
        end
    end

    if not hasKey then
        notifyPlayer(src, 'Llaves', 'No tienes las llaves de este vehículo.', 'error')
        return
    end

    TriggerClientEvent('luxury_garage:client:toggleLock', src, netId)
end)

-- Exports de Llaves
exports('HasKeys', function(plate, cid)
    return (vehicleKeys[plate] and vehicleKeys[plate][cid]) or false
end)

exports('GiveKeys', function(plate, cid)
    vehicleKeys[plate] = vehicleKeys[plate] or {}
    vehicleKeys[plate][cid] = true
    return true
end)
