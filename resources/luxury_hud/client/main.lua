-- luxury_hud: Lógica de Cliente - Telemetría Origen HUD & Integración ESX
-- Compatible con ESX Legacy, ESX v1 Final y Luxury Framework

local ESX = nil
local isCinematic = false
local seatbeltOn = false
local lastSpeed = 0.0
local isSettingsOpen = false

-- Estados de ESX
local esxHunger = 100
local esxThirst = 100
local esxAccounts = { cash = 0, bank = 0, black = 0 }

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

-- Inicialización de ESX
CreateThread(function()
    while ESX == nil do
        ESX = getESX()
        if not ESX then Wait(250) end
    end

    -- Si el jugador ya está cargado, pedir cuentas iniciales
    if ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
        local pData = ESX.GetPlayerData()
        if pData and pData.accounts then
            for _, acc in ipairs(pData.accounts) do
                if acc.name == 'money' or acc.name == 'cash' then esxAccounts.cash = acc.money
                elseif acc.name == 'bank' then esxAccounts.bank = acc.money
                elseif acc.name == 'black_money' then esxAccounts.black = acc.money end
            end
            SendNUIMessage({ action = 'UPDATE_MONEY', payload = esxAccounts })
        end
    end
end)

-- Escuchar carga de jugador en ESX
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if xPlayer and xPlayer.accounts then
        for _, acc in ipairs(xPlayer.accounts) do
            if acc.name == 'money' or acc.name == 'cash' then esxAccounts.cash = acc.money
            elseif acc.name == 'bank' then esxAccounts.bank = acc.money
            elseif acc.name == 'black_money' then esxAccounts.black = acc.money end
        end
    end
    SendNUIMessage({ action = 'UPDATE_MONEY', payload = esxAccounts })
end)

-- Escuchar actualización de cuentas en ESX
RegisterNetEvent('esx:setAccountMoney', function(account)
    if account.name == 'money' or account.name == 'cash' then esxAccounts.cash = account.money
    elseif account.name == 'bank' then esxAccounts.bank = account.money
    elseif account.name == 'black_money' then esxAccounts.black = account.money end
    SendNUIMessage({ action = 'UPDATE_MONEY', payload = esxAccounts })
end)

-- Soporte directo con eventos de Luxury Core
RegisterNetEvent('luxury_core:client:updateMoney', function(cash, bank)
    esxAccounts.cash = cash or esxAccounts.cash
    esxAccounts.bank = bank or esxAccounts.bank
    SendNUIMessage({ action = 'UPDATE_MONEY', payload = esxAccounts })
end)

-- Escuchar tick de estado de esx_status (Hambre y Sed)
RegisterNetEvent('esx_status:onTick', function(statuses)
    for _, status in ipairs(statuses or {}) do
        if status.name == 'hunger' then
            esxHunger = math.max(0, math.min(100, math.floor(status.val / 10000)))
        elseif status.name == 'thirst' then
            esxThirst = math.max(0, math.min(100, math.floor(status.val / 10000)))
        end
    end
end)

-- Direcciones cardinales para la Brújula Origen
local function getCardinalDirection(heading)
    if heading >= 337.5 or heading < 22.5 then return 'N'
    elseif heading >= 22.5 and heading < 67.5 then return 'NE'
    elseif heading >= 67.5 and heading < 112.5 then return 'E'
    elseif heading >= 112.5 and heading < 157.5 then return 'SE'
    elseif heading >= 157.5 and heading < 202.5 then return 'S'
    elseif heading >= 202.5 and heading < 247.5 then return 'SW'
    elseif heading >= 247.5 and heading < 292.5 then return 'W'
    elseif heading >= 292.5 and heading < 337.5 then return 'NW'
    end
    return 'N'
end

-- Registro del comando cinemático
RegisterCommand(Config.CinematicCommand or 'cinematic', function()
    isCinematic = not isCinematic
    SendNUIMessage({
        action = 'TOGGLE_CINEMATIC',
        payload = { active = isCinematic }
    })
    DisplayRadar(not isCinematic and IsPedInAnyVehicle(PlayerPedId(), false))
end, false)

-- Registro del comando del Menú de Ajustes (/hud)
RegisterCommand(Config.SettingsCommand or 'hud', function()
    isSettingsOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OPEN_SETTINGS'
    })
end, false)

-- Registro de Keymapping para el Cinturón de Seguridad
RegisterKeyMapping('seatbelt', 'Alternar Cinturón de Seguridad', 'keyboard', Config.SeatbeltKey or 'B')
RegisterCommand('seatbelt', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        seatbeltOn = not seatbeltOn
        if seatbeltOn then
            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        else
            PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        end
        SendNUIMessage({
            action = 'UPDATE_SEATBELT',
            payload = { active = seatbeltOn }
        })
    end
end, false)

--- Hilo de Vitals y Brújula del Jugador
CreateThread(function()
    while true do
        local sleep = Config.FootRefresh or 250
        local ped = PlayerPedId()

        if not isCinematic then
            local isDead = IsEntityDead(ped)
            if isDead and Config.HideOnDead then
                SendNUIMessage({ action = 'SET_VISIBLE', payload = { visible = false } })
                Wait(1000)
            else
                local maxHealth = GetEntityMaxHealth(ped)
                local curHealth = GetEntityHealth(ped)
                local healthPercent = math.max(0, math.min(100, math.floor(((curHealth - 100) / (maxHealth - 100)) * 100)))
                local armor = GetPedArmour(ped)
                local stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(PlayerId()))
                
                -- Hambre y Sed (prioriza esx_status si está disponible, luego LocalPlayer.state)
                local hunger = esxHunger or LocalPlayer.state.hunger or 100
                local thirst = esxThirst or LocalPlayer.state.thirst or 100
                local stress = LocalPlayer.state.stress or 0

                -- Oxígeno al bucear
                local isUnderwater = IsPedSwimmingUnderWater(ped)
                local oxygen = 100
                if isUnderwater then
                    oxygen = math.max(0, math.min(100, math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10)))
                end

                -- Proximidad y estado de voz (pma-voice / mumble-voip)
                local voiceRange = LocalPlayer.state.proximity and LocalPlayer.state.proximity.mode or 2
                local isTalking = NetworkIsPlayerTalking(PlayerId())
                local isRadio = LocalPlayer.state.radioActive or false

                -- Ubicación, Calle y Brújula
                local pCoords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local cardinal = getCardinalDirection(heading)
                local streetHash, crossHash = GetStreetNameAtCoord(pCoords.x, pCoords.y, pCoords.z)
                local streetName = GetStreetNameFromHashKey(streetHash) or 'Los Santos'
                local crossName = crossHash ~= 0 and GetStreetNameFromHashKey(crossHash) or ''
                local zoneCode = GetNameOfZone(pCoords.x, pCoords.y, pCoords.z)
                local zoneLabel = GetLabelText(zoneCode) or zoneCode
                local timeStr = ('%02d:%02d'):format(GetClockHours(), GetClockMinutes())

                SendNUIMessage({
                    action = 'UPDATE_STATUS',
                    payload = {
                        health = healthPercent,
                        armor = armor,
                        hunger = hunger,
                        thirst = thirst,
                        stamina = stamina,
                        stress = stress,
                        oxygen = oxygen,
                        isUnderwater = isUnderwater,
                        voice = {
                            range = voiceRange,
                            talking = isTalking,
                            radio = isRadio
                        },
                        location = {
                            street = (crossName ~= '' and (streetName .. ' / ' .. crossName) or streetName),
                            zone = zoneLabel,
                            heading = math.floor(heading),
                            cardinal = cardinal,
                            time = timeStr
                        }
                    }
                })
            end
        end

        Wait(sleep)
    end
end)

--- Hilo de Telemetría Vehicular (Velocímetro Origen HUD)
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) and not isCinematic then
            sleep = Config.VehicleRefresh or 60
            local veh = GetVehiclePedIsIn(ped, false)
            
            -- Minimapa activo en vehículo
            DisplayRadar(true)

            local speedKmh = GetEntitySpeed(veh) * 3.6
            local speedMph = GetEntitySpeed(veh) * 2.236936
            local displaySpeed = math.floor(Config.SpeedUnit == 'mph' and speedMph or speedKmh)
            local rpm = math.floor(GetVehicleCurrentRpm(veh) * 100)
            local gear = GetVehicleCurrentGear(veh)
            local fuel = math.floor(GetVehicleFuelLevel(veh))
            local engineHealth = math.floor(GetVehicleEngineHealth(veh) / 10)
            local _, lightState, highBeams = GetVehicleLightsState(veh)
            local isLocked = GetVehicleDoorLockStatus(veh) > 1

            -- Eyector de cinturón en choque
            if not seatbeltOn and lastSpeed > 75.0 and (lastSpeed - speedKmh) > 50.0 then
                local coords = GetEntityCoords(ped)
                local forward = GetEntityForwardVector(ped)
                SetEntityCoords(ped, coords.x + forward.x * 2.0, coords.y + forward.y * 2.0, coords.z + 0.5, true, true, true, true)
                SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
                ApplyDamageToPed(ped, math.random(15, 45), false)
            end
            lastSpeed = speedKmh

            SendNUIMessage({
                action = 'UPDATE_VEHICLE',
                payload = {
                    inVehicle = true,
                    speed = displaySpeed,
                    speedUnit = Config.SpeedUnit,
                    rpm = rpm,
                    gear = (gear == 0 and 'R' or gear),
                    fuel = fuel,
                    engine = engineHealth,
                    seatbelt = seatbeltOn,
                    lights = lightState,
                    locked = isLocked
                }
            })
        else
            if lastSpeed ~= 0.0 then
                DisplayRadar(false)
                seatbeltOn = false
                lastSpeed = 0.0
                SendNUIMessage({
                    action = 'UPDATE_VEHICLE',
                    payload = { inVehicle = false }
                })
            end
        end

        Wait(sleep)
    end
end)

---------------------------------------------------------------------
-- NUI Callbacks para el Menú de Ajustes (/hud)
---------------------------------------------------------------------

RegisterNUICallback('closeSettings', function(_, cb)
    isSettingsOpen = false
    SetNuiFocus(false, false)
    cb({ status = 'ok' })
end)

RegisterNUICallback('saveSettings', function(data, cb)
    TriggerServerEvent('luxury_hud:server:saveSettings', data)
    cb({ status = 'ok' })
end)
