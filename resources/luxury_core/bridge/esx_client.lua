-- luxury_core: Puente de Compatibilidad con ESX (Cliente)
ESX = ESX or {}
ESX.PlayerData = {}
ESX.ServerCallbacks = {}
local currentRequestId = 0

function ESX.IsPlayerLoaded()
    return LocalPlayer.state.isLoggedIn or false
end

function ESX.GetPlayerData()
    return ESX.PlayerData
end

function ESX.SetPlayerData(key, val)
    ESX.PlayerData[key] = val
end

function ESX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
    if Luxury and Luxury.Notify then
        Luxury.Notify(msg, 'info', 4000)
    else
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(tostring(msg))
        EndTextCommandThefeedPostTicker(false, true)
    end
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandDisplayHelp(0, false, beep or false, duration or -1)
end

function ESX.TriggerServerCallback(name, cb, ...)
    currentRequestId = (currentRequestId + 1) % 1000000
    local reqId = currentRequestId
    ESX.ServerCallbacks[reqId] = cb

    TriggerServerEvent('esx:triggerServerCallback', name, reqId, ...)

    -- Timeout de 15 segundos
    SetTimeout(15000, function()
        if ESX.ServerCallbacks[reqId] then
            ESX.ServerCallbacks[reqId] = nil
        end
    end)
end

RegisterNetEvent('esx:serverCallback', function(requestId, ...)
    local cb = ESX.ServerCallbacks[requestId]
    if cb then
        ESX.ServerCallbacks[requestId] = nil
        cb(...)
    end
end)

-- Sincronizar datos ESX al recibir actualización del Core
RegisterNetEvent('luxury:client:update', function(data)
    ESX.PlayerData.identifier = data.citizenid or ''
    ESX.PlayerData.accounts = {
        { name = 'cash', money = data.cash or 0, label = 'Efectivo' },
        { name = 'bank', money = data.bank or 0, label = 'Banco' }
    }
    ESX.PlayerData.money = data.cash or 0
    ESX.PlayerData.job = data.job or {}
    ESX.PlayerData.charinfo = data.charinfo or {}

    TriggerEvent('esx:setJob', ESX.PlayerData.job)
end)

RegisterNetEvent('esx:showNotification', function(msg, notifyType)
    ESX.ShowNotification(msg, notifyType)
end)

RegisterNetEvent('esx:showHelpNotification', function(msg, duration)
    ESX.ShowHelpNotification(msg, false, false, duration)
end)

-- Handlers clásicos
AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

exports('getSharedObject', function() return ESX end)
exports('GetSharedObject', function() return ESX end)
exports('GetESX', function() return ESX end)
