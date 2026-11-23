-- luxury_garage: Lógica de Cliente - Garajes, Depósito y Llaves Remotas
-- Compatible con ESX, QBCore y Luxury Framework

local isMenuOpen = false
local currentGarage = nil
local currentIsImpound = false

--- Crear Blips en el Mapa para Garajes e Incautados
CreateThread(function()
    -- Garajes Normales (Icono de Garaje verde)
    for id, garage in pairs(Config.Garages or {}) do
        local blip = AddBlipForCoord(garage.marker.x, garage.marker.y, garage.marker.z)
        SetBlipSprite(blip, 357)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.75)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(garage.label or "Garaje Público")
        EndTextCommandSetBlipName(blip)
    end

    -- Depósitos de Incautados (Icono de Depósito amarillo)
    for id, imp in pairs(Config.Impounds or {}) do
        local blip = AddBlipForCoord(imp.marker.x, imp.marker.y, imp.marker.z)
        SetBlipSprite(blip, 68)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.75)
        SetBlipColour(blip, 5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(imp.label or "Depósito Municipal")
        EndTextCommandSetBlipName(blip)
    end
end)

--- Mostrar Notificación o TextUI
local function showTextUI(text)
    if exports['luxury_notify'] then
        exports['luxury_notify']:TextUI(text, 'right')
    else
        BeginTextCommandDisplayHelp("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayHelp(0, false, true, -1)
    end
end

local function hideTextUI()
    if exports['luxury_notify'] then
        exports['luxury_notify']:HideUI()
    end
end

--- Hilo de Detección de Garajes y Depósitos
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if not isMenuOpen and not IsEntityDead(ped) then
            local pCoords = GetEntityCoords(ped)
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local nearZone = false

            -- 1. Garajes Públicos
            for id, garage in pairs(Config.Garages or {}) do
                local dist = #(pCoords - garage.marker)
                if dist < 15.0 then
                    sleep = 0
                    DrawMarker(36, garage.marker.x, garage.marker.y, garage.marker.z + 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 31, 111, 235, 180, false, false, 2, true, nil, nil, false)
                    
                    if dist < 3.0 then
                        nearZone = true
                        currentGarage = id
                        currentIsImpound = false

                        if inVehicle then
                            showTextUI("Presiona [E] para Guardar Vehículo")
                            if IsControlJustPressed(0, 38) then
                                local veh = GetVehiclePedIsIn(ped, false)
                                local plate = GetVehicleNumberPlateText(veh)
                                local engine = math.floor(GetVehicleEngineHealth(veh))
                                local body = math.floor(GetVehicleBodyHealth(veh))
                                local fuel = math.floor(GetVehicleFuelLevel(veh))
                                TriggerServerEvent('luxury_garage:server:storeVehicle', plate:gsub("%s+", ""), id, {
                                    engine = engine,
                                    body = body,
                                    fuel = fuel
                                })
                            end
                        else
                            showTextUI("Presiona [E] para Abrir Garaje")
                            if IsControlJustPressed(0, 38) then
                                TriggerServerEvent('luxury_garage:server:requestVehicles', id, false)
                            end
                        end
                        break
                    end
                end
            end

            -- 2. Depósitos / Incautados
            if not nearZone and not inVehicle then
                for id, imp in pairs(Config.Impounds or {}) do
                    local dist = #(pCoords - imp.marker)
                    if dist < 15.0 then
                        sleep = 0
                        DrawMarker(39, imp.marker.x, imp.marker.y, imp.marker.z + 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 245, 158, 11, 180, false, false, 2, true, nil, nil, false)
                        
                        if dist < 3.0 then
                            nearZone = true
                            currentGarage = id
                            currentIsImpound = true
                            showTextUI("Presiona [E] para Acceder al Depósito")
                            if IsControlJustPressed(0, 38) then
                                TriggerServerEvent('luxury_garage:server:requestVehicles', id, true)
                            end
                            break
                        end
                    end
                end
            end

            if not nearZone then
                hideTextUI()
            end
        end

        Wait(sleep)
    end
end)

--- Mando a Distancia / Cerrar y Abrir Vehículo con Tecla (Keybind)
RegisterKeyMapping('toggleVehicleLock', 'Abrir/Cerrar Vehículo (Mando)', 'keyboard', Config.LockKey or 'U')
RegisterCommand('toggleVehicleLock', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local targetVeh = nil

    if IsPedInAnyVehicle(ped, false) then
        targetVeh = GetVehiclePedIsIn(ped, false)
    else
        targetVeh = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    end

    if targetVeh and DoesEntityExist(targetVeh) then
        local plate = GetVehicleNumberPlateText(targetVeh):gsub("%s+", "")
        local netId = NetworkGetNetworkIdFromEntity(targetVeh)
        TriggerServerEvent('luxury_garage:server:toggleLock', plate, netId)
    else
        if exports['luxury_notify'] then
            exports['luxury_notify']:Alert('Llaves', 'No hay ningún vehículo cerca.', 3000, 'error')
        end
    end
end, false)

--- Efectos Visuales y Sonoros de Apertura/Cierre
RegisterNetEvent('luxury_garage:client:toggleLock', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or not DoesEntityExist(veh) then return end

    local ped = PlayerPedId()
    local isLocked = GetVehicleDoorLockStatus(veh) > 1

    -- Animación de sacar y pulsar el mando remoto
    if not IsPedInAnyVehicle(ped, false) then
        RequestAnimDict("anim@mp_player_intmenu@key_fob@")
        while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do Wait(10) end
        TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, 8.0, -1, 48, 1, false, false, false)
    end

    -- Alternar cerraduras
    if isLocked then
        SetVehicleDoorsLocked(veh, 1)
        PlaySoundFrontend(-1, "BUTTON", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        SetVehicleLights(veh, 2)
        Wait(200)
        SetVehicleLights(veh, 0)
        Wait(200)
        SetVehicleLights(veh, 2)
        Wait(200)
        SetVehicleLights(veh, 0)
        if exports['luxury_notify'] then
            exports['luxury_notify']:Alert('Vehículo', 'Vehículo abierto.', 2500, 'success')
        end
    else
        SetVehicleDoorsLocked(veh, 2)
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        SetVehicleLights(veh, 2)
        Wait(250)
        SetVehicleLights(veh, 0)
        if exports['luxury_notify'] then
            exports['luxury_notify']:Alert('Vehículo', 'Vehículo cerrado con llave.', 2500, 'info')
        end
    end
end)

--- Abrir Menú NUI de Garaje
RegisterNetEvent('luxury_garage:client:openMenu', function(data)
    isMenuOpen = true
    hideTextUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OPEN_GARAGE',
        payload = data
    })
end)

--- Spawnear Vehículo en el Mundo
RegisterNetEvent('luxury_garage:client:spawnVehicle', function(data)
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_GARAGE' })

    local modelHash = GetHashKey(data.model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end

    local spawnCoords = data.spawn
    local veh = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    
    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleEngineHealth(veh, tonumber(data.engine) or 1000.0)
    SetVehicleBodyHealth(veh, tonumber(data.body) or 1000.0)
    SetVehicleFuelLevel(veh, tonumber(data.fuel) or 100.0)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetModelAsNoLongerNeeded(modelHash)

    -- Sentar al jugador en el asiento del conductor
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
end)

--- Confirmación de Vehículo Guardado
RegisterNetEvent('luxury_garage:client:vehicleStored', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        DeleteEntity(veh)
    end
end)

--- NUI Callback: Sacar Vehículo
RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('luxury_garage:server:spawnVehicle', data.plate, currentGarage)
    cb('ok')
end)

--- NUI Callback: Pagar Depósito
RegisterNUICallback('payImpound', function(data, cb)
    TriggerServerEvent('luxury_garage:server:payImpound', data.plate, currentGarage)
    cb('ok')
end)

--- NUI Callback: Cerrar Menú
RegisterNUICallback('close', function(_, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
