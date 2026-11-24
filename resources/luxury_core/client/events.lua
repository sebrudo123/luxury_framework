-- luxury_core: Eventos de Red del Cliente (Client Events)
local isSpawned = false

-- Solicitar la carga del jugador en cuanto el cliente esté conectado a la red
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(250)
    end
    TriggerServerEvent('luxury:server:requestLoad')
end)

-- Manejo de Spawn y teletransporte a coordenadas guardadas con carga de colisiones
RegisterNetEvent('luxury:client:spawnPlayer', function(coords, savedArmor)
    local ped = PlayerPedId()
    coords = coords or Config.DefaultSpawn

    -- Congelar ped mientras cargan colisiones del mapa para evitar caídas al vacío
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, true)
    SetEntityHeading(ped, coords.heading or 0.0)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(50)
    end

    FreezeEntityPosition(ped, false)
    if savedArmor and tonumber(savedArmor) and tonumber(savedArmor) > 0 then
        SetPedArmour(ped, math.min(100, math.floor(tonumber(savedArmor))))
    end
    isSpawned = true
end)

-- Sincronización de datos del jugador
RegisterNetEvent('luxury:client:update', function(data)
    PlayerData = data
end)

function IsSpawned()
    return isSpawned
end
