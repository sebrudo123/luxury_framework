-- luxury_core: Centinela de Seguridad del Cliente Avanzado (Anti-Cheat & Anti-Dump Engine)
local sessionToken = nil
local isSecured = false

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

-- Lista negra de variables globales inyectadas por herramientas de trucos (Eulen, RedEngine, Ham, etc.)
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

RegisterNetEvent('luxury:security:handshakeResponse', function(token)
    sessionToken = token
    isSecured = true
end)

-- 2) Respuesta al desafío de latido del servidor (Heartbeat)
RegisterNetEvent('luxury:security:heartbeatChallenge', function(challenge)
    if not isSecured then return end
    TriggerServerEvent('luxury:security:heartbeatResponse', challenge, tostring(challenge + 1337))
end)

-- 3) Detector de detención forzada del recurso desde ejecutores
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('luxury:exploit:triggerBypass')
    end
end)

-- 4) Escáner de Memoria y Variables de Inyección en Tiempo Real
CreateThread(function()
    while true do
        Wait(3000) -- Escaneo heurístico cada 3 segundos

        local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
        local isAdmin = (playerGroup == 'admin' or playerGroup == 'mod')

        if not isAdmin then
            -- A) Escaneo de tablas globales inyectadas en _G
            for _, globalName in ipairs(CheatGlobals) do
                if _G[globalName] ~= nil then
                    TriggerServerEvent('luxury:security:flagPlayer', ('Inyección de menú / ejecutor detectado en memoria global (_G.%s)'):format(globalName))
                    break
                end
            end

            -- B) Detección de exposición de librería debug interna
            if debug and (debug.getinfo or debug.setupvalue) then
                -- Si debug no es nativo de FiveM y fue expuesto por un inyector
                local info = debug.getinfo(TriggerServerEvent)
                if info and info.what == 'C' and _G['debug']['setupvalue'] then
                    TriggerServerEvent('luxury:security:flagPlayer', 'Manipulación de funciones nativas / Hooking en TriggerServerEvent')
                end
            end
        end
    end
end)

-- 5) Bucle de Vigilancia en Tiempo Real (Anti-Godmode, Anti-Speedhack, Wallhack, Armas Ilegales)
CreateThread(function()
    while true do
        Wait(1000) -- Coste CPU de 0.00ms resmon

        if LocalPlayer.state.isLoggedIn and not LocalPlayer.state.isDead then
            local ped = PlayerPedId()
            local playerId = PlayerId()
            local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
            local isAdmin = (playerGroup == 'admin' or playerGroup == 'mod')

            if not isAdmin then
                -- A) Neutralización silenciosa de Godmode (Sin falsos positivos por spawn, tiendas de ropa o muerte)
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
                    TriggerServerEvent('luxury:security:flagPlayer', ('Posesión de arma militar prohibida: %s'):format(BlacklistedWeapons[currentWeapon]))
                end

                -- C) Detección de Speedhack a pie (Tolerancia alta para saltos, rampas o ragdoll)
                if not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) and not IsPedFalling(ped) and not IsPedInParachuteFreeFall(ped) and not IsPedSwimming(ped) and not IsPedClimbing(ped) then
                    local speed = GetEntitySpeed(ped)
                    if speed > 25.0 then
                        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                    end
                end

                -- D) Detección de Salud Modificada / Inflada (Corrección directa sin baneo falso)
                local health = GetEntityHealth(ped)
                if health > 200 then
                    SetEntityHealth(ped, 200)
                end

                -- E) Detección de Modo Espectador / Freecam
                if NetworkIsInSpectatorMode() and not LocalPlayer.state.isDead then
                    NetworkSetInSpectatorMode(false, ped)
                end

                -- F) Detección de Visión Térmica / Nocturna (Wallhack)
                if GetUsingnightvision() or GetUsingseethrough() then
                    SetNightvision(false)
                    SetSeethrough(false)
                end

                -- G) Bloqueo y Corrección de Modificador de Daño (One-Shot Kill Hack)
                SetPlayerWeaponDamageModifier(playerId, 1.0)
                SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
                SetPlayerVehicleDamageModifier(playerId, 1.0)
            end
        end
    end
end)

exports('GetSessionToken', function()
    return sessionToken
end)
