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
    local meta = data.metadata or {}
    local jobData = data.job or {}
    local gangData = data.gang or {}

    QBCore.PlayerData = {
        citizenid = data.citizenid or '',
        money = {
            cash = data.cash or 0,
            bank = data.bank or 0,
            crypto = data.crypto or 0,
            black_money = data.black_money or 0
        },
        job = {
            name = jobData.name or 'unemployed',
            label = jobData.label or 'Desempleado',
            payment = jobData.salary or 0,
            onduty = jobData.onduty ~= false,
            isboss = jobData.isBoss == true,
            grade = {
                level = jobData.grade or 0,
                name = jobData.grade_label or 'Rango 0'
            }
        },
        gang = {
            name = gangData.name or 'none',
            label = gangData.label or 'Ninguna',
            isboss = gangData.isBoss == true,
            grade = {
                level = gangData.grade or 0,
                name = gangData.grade_label or 'Sin banda'
            }
        },
        charinfo = data.charinfo or {},
        metadata = {
            hunger = data.needs and data.needs.hunger or 100,
            thirst = data.needs and data.needs.thirst or 100,
            isdead = meta.isdead == true,
            inlaststand = meta.inlaststand == true,
            injail = meta.injail or 0,
            armor = meta.armor or 0,
            stress = meta.stress or 0,
            handcuffed = meta.handcuffed == true,
            callsign = meta.callsign or 'NO-CALLSIGN'
        }
    }

    TriggerEvent('QBCore:Client:OnJobUpdate', QBCore.PlayerData.job)
    TriggerEvent('QBCore:Client:OnGangUpdate', QBCore.PlayerData.gang)
    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
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
