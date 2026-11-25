-- luxury_core: Centinela de Seguridad del Cliente Avanzado (Luxury Sentinel v2)
local sessionToken = nil
local isSecured = false
local allowedResources = nil

-- Lista negra de armas pesadas y de troleo masivo (Griefing Weapons)
local BlacklistedWeapons = {
    [`WEAPON_MINIGUN`] = 'Minigun',
    [`WEAPON_RPG`] = 'RPG / Lanzacohetes',
    [`WEAPON_HOMINGLAUNCHER`] = 'Lanzamisiles Guiado',
    [`WEAPON_RAILGUN`] = 'Cañón de Riel (Railgun)',
    [`WEAPON_COMPACTLAUNCHER`] = 'Lanzagranadas Compacto',
    [`WEAPON_GRENADELAUNCHER`] = 'Lanzagranadas M32',
    [`WEAPON_FIREWORK`] = 'Lanzador de Fuegos Artificiales',
    [`WEAPON_WIDOWMAKER`] = 'Widowmaker Láser'
}

-- Lista negra de variables globales inyectadas por herramientas de trucos
local CheatGlobals = {
    'eulen', 'redengine', 'lynx', 'ham', 'brutan', 'tiago', 'lux', 'desudo',
    'dopamine', 'skid', 'fendin', 'redstrikers', 'fallout', 'chocohax',
    'injected', 'Executor', 'CheatEngine', 'Watermalone', 'Swag', 'Alikhan'
}

-- 1) Handshake de seguridad al inicializarse el cliente
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(250)
    end
    TriggerServerEvent('luxury:security:requestHandshake')
end)

RegisterNetEvent('luxury:security:handshakeResponse', function(token, serverResourceList)
    sessionToken = token
    if type(serverResourceList) == 'table' then
        allowedResources = serverResourceList
    end
    isSecured = true
end)

RegisterNetEvent('luxury:security:addAllowedResource', function(resName)
    if allowedResources and resName then
        allowedResources[resName] = true
    end
end)

-- 2) Respuesta al desafío criptográfico de latido del servidor (Heartbeat)
RegisterNetEvent('luxury:security:heartbeatChallenge', function(challenge)
    if not isSecured or not challenge then return end
    local num = tonumber(challenge)
    if not num then return end
    local hash = tostring((num * 7 + 1337) % 9999999)
    TriggerServerEvent('luxury:security:heartbeatResponse', num, hash)
end)

-- 3) Detector de detención forzada del recurso desde ejecutores
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('luxury:exploit:triggerBypass')
    end
end)

-- 4) Escáner de Memoria, Variables de Inyección y Recursos Fantasma (cada 4 segundos)
CreateThread(function()
    while true do
        Wait(4000)

        local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
        local isAdmin = (playerGroup == 'admin' or playerGroup == 'mod')

        if isSecured and not isAdmin then
            -- A) Escaneo de tablas globales inyectadas en _G
            for _, globalName in ipairs(CheatGlobals) do
                if _G[globalName] ~= nil then
                    TriggerServerEvent('luxury:security:flagPlayer', ('Inyección de menú / ejecutor detectado en memoria global (_G.%s)'):format(globalName), 'high')
                    break
                end
            end

            -- B) Detección de exposición o hooking de librería debug interna
            if debug and (debug.getinfo or debug.setupvalue) then
                local info = debug.getinfo(TriggerServerEvent)
                if info and info.what == 'C' and _G['debug']['setupvalue'] then
                    TriggerServerEvent('luxury:security:flagPlayer', 'Manipulación de funciones nativas / Hooking en TriggerServerEvent', 'high')
                end
            end

            -- C) Detección de inyección de recursos fantasma no iniciados por el servidor
            if allowedResources then
                local total = GetNumResources()
                for i = 0, total - 1 do
                    local rName = GetResourceByFindIndex(i)
                    if rName and GetResourceState(rName) == 'started' and not allowedResources[rName] then
                        TriggerServerEvent('luxury:security:flagPlayer', ('Inyección de recurso cliente no autorizado (%s)'):format(rName), 'high')
                        break
                    end
                end
            end
        end
    end
end)

-- 5) Bucle de Vigilancia en Tiempo Real (Anti-Godmode, Armas, Speedhack, Invisibilidad, Freecam)
CreateThread(function()
    local invisWarnings = 0
    local freecamWarnings = 0

    while true do
        Wait(1000)

        if LocalPlayer.state.isLoggedIn and not LocalPlayer.state.isDead then
            local ped = PlayerPedId()
            local playerId = PlayerId()
            local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
            local isAdmin = (playerGroup == 'admin' or playerGroup == 'mod')

            if not isAdmin then
                -- A) Neutralización silenciosa de Godmode
                if GetPlayerInvincible(playerId) or GetPlayerInvincible_2(playerId) then
                    SetPlayerInvincible(playerId, false)
                end
                if not GetEntityCanBeDamaged(ped) then
                    SetEntityCanBeDamaged(ped, true)
                end

                -- B) Detección de Armas Prohibidas en la Mano
                local _, currentWeapon = GetCurrentPedWeapon(ped, true)
                if BlacklistedWeapons[currentWeapon] then
                    RemoveWeaponFromPed(ped, currentWeapon)
                    TriggerServerEvent('luxury:security:flagPlayer', ('Posesión de arma militar prohibida: %s'):format(BlacklistedWeapons[currentWeapon]), 'high')
                end

                -- C) Detección de Speedhack a pie
                if not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) and not IsPedFalling(ped) and not IsPedInParachuteFreeFall(ped) and not IsPedSwimming(ped) and not IsPedClimbing(ped) then
                    local speed = GetEntitySpeed(ped)
                    if speed > 25.0 then
                        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                    end
                end

                -- D) Salud inflada
                if GetEntityHealth(ped) > 200 then
                    SetEntityHealth(ped, 200)
                end

                -- E) Espectador no autorizado
                if NetworkIsInSpectatorMode() and not LocalPlayer.state.isDead and not LocalPlayer.state['luxury:spectating'] then
                    NetworkSetInSpectatorMode(false, ped)
                    TriggerServerEvent('luxury:security:flagPlayer', 'Modo espectador no autorizado (Spectate Hack)')
                end

                -- F) Visión Térmica / Nocturna (Wallhack)
                if GetUsingnightvision() or GetUsingseethrough() then
                    SetNightvision(false)
                    SetSeethrough(false)
                end

                -- G) Bloqueo de Modificadores de Daño y Munición Infinita
                SetPlayerWeaponDamageModifier(playerId, 1.0)
                SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
                SetPlayerVehicleDamageModifier(playerId, 1.0)
                SetPedInfiniteAmmoClip(ped, false)

                -- H) Anti-Invisibilidad no autorizada (en dimensión 0 y sin transición de cámara)
                local instance = LocalPlayer.state.instance or 0
                if instance == 0 and not IsEntityVisible(ped) and not IsPlayerSwitchInProgress() and not IsScreenFadedOut() then
                    invisWarnings = invisWarnings + 1
                    SetEntityVisible(ped, true, false)
                    if invisWarnings >= 3 then
                        invisWarnings = 0
                        TriggerServerEvent('luxury:security:flagPlayer', 'Invisibilidad forzada detectada en el jugador')
                    end
                else
                    invisWarnings = 0
                end

                -- I) Anti-Freecam ilegal (si la cámara se aleja >45m a pie sin cámara cinemática/autorizada)
                if not IsPedInAnyVehicle(ped, false) and not IsCinematicCamRendering() and not LocalPlayer.state['luxury:allowFreecam'] and not IsScreenFadedOut() and instance == 0 then
                    local camDist = #(GetGameplayCamCoord() - GetEntityCoords(ped))
                    if camDist > 45.0 then
                        freecamWarnings = freecamWarnings + 1
                        if freecamWarnings >= 3 then
                            freecamWarnings = 0
                            RenderScriptCams(false, false, 0, true, true)
                            TriggerServerEvent('luxury:security:flagPlayer', ('Freecam ilegal detectado (Distancia cámara: %.1fm)'):format(camDist))
                        end
                    else
                        freecamWarnings = 0
                    end
                end
            end
        end
    end
end)

exports('GetSessionToken', function()
    return sessionToken
end)
