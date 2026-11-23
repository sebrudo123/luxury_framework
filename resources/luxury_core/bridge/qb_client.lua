-- luxury_core: Puente de Compatibilidad con QBCore (Cliente)
QBCore = QBCore or {}
QBCore.Functions = {}
QBCore.PlayerData = {}
QBCore.ServerCallbacks = {}

function QBCore.Functions.GetPlayerData(cb)
    if cb then cb(QBCore.PlayerData) end
    return QBCore.PlayerData
end

function QBCore.Functions.Notify(text, notifyType, length)
    if Luxury and Luxury.Notify then
        Luxury.Notify(text, notifyType or 'info', length or 4000)
    else
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(tostring(text))
        EndTextCommandThefeedPostTicker(false, true)
    end
end

function QBCore.Functions.TriggerCallback(name, cb, ...)
    QBCore.ServerCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
end

RegisterNetEvent('QBCore:Client:CallbackResponse', function(name, ...)
    local cb = QBCore.ServerCallbacks[name]
    if cb then
        QBCore.ServerCallbacks[name] = nil
        cb(...)
    end
end)

function QBCore.Functions.GetClosestPlayer()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestPlayer, closestDist = -1, -1

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local dist = #(coords - GetEntityCoords(targetPed))
            if closestDist == -1 or dist < closestDist then
                closestPlayer = playerId
                closestDist = dist
            end
        end
    end

    return closestPlayer, closestDist
end

function QBCore.Functions.GetClosestVehicle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    return veh, #(coords - GetEntityCoords(veh))
end

-- Sincronizar datos QBCore al recibir actualización de Core
RegisterNetEvent('luxury:client:update', function(data)
    QBCore.PlayerData = {
        citizenid = data.citizenid or '',
        money = { cash = data.cash or 0, bank = data.bank or 0 },
        job = data.job or {},
        charinfo = data.charinfo or {},
        metadata = {
            hunger = data.needs and data.needs.hunger or 100,
            thirst = data.needs and data.needs.thirst or 100
        }
    }

    TriggerEvent('QBCore:Client:OnJobUpdate', data.job)
end)

RegisterNetEvent('QBCore:Notify', function(text, notifyType, length)
    QBCore.Functions.Notify(text, notifyType, length)
end)

AddEventHandler('QBCore:GetObject', function(cb)
    cb(QBCore)
end)

exports('GetCoreObject', function() return QBCore end)
exports('GetSharedObject', function() return QBCore end)
exports('GetQBCore', function() return QBCore end)
