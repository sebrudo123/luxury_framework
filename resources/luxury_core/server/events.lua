-- luxury_core: Manejadores de Eventos de Red del Servidor (Server Events)

-- Solicitud de carga inicial del jugador
RegisterNetEvent('luxury:server:requestLoad', function()
    local src = source
    if Security and not Security.CheckRateLimit(src) then return end

    -- Si luxury_multicharacter está activo, delegamos en el selector de personajes
    if GetResourceState('luxury_multicharacter') == 'started' then return end

    if not Core.Players[src] then
        Core.LoadPlayer(src)
    end
end)

-- Cambio de personaje / Logout hacia selector Multi-Character
RegisterNetEvent('luxury:server:logout', function()
    local src = source
    Core.UnloadPlayer(src, true)
end)

-- Actualización periódica de coordenadas con validación Anti-Teleport
RegisterNetEvent('luxury:server:updateCoords', function(coords)
    local src = source
    if Security and not Security.CheckRateLimit(src) then return end

    local player = Core.Players[src]
    if player and coords then
        if Security and Security.ValidateCoords then
            if Security.ValidateCoords(src, coords) then
                player:setCoords(coords)
            end
        else
            player:setCoords(coords)
        end
    end
end)

-- Desconexión de un jugador (Anti-Combat Log + Log Discord + Limpieza)
AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = Core.Players[src]

    if player then
        local ped = GetPlayerPed(src)
        local dropCoords = player:getCoords()
        if ped and DoesEntityExist(ped) then
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            dropCoords = { x = pos.x, y = pos.y, z = pos.z, heading = heading }
            player:setCoords(dropCoords)
        end

        -- Anti-Combat Log: notificar a jugadores cercanos para dibujar marcador 3D temporal
        if dropCoords and dropCoords.x then
            local duration = Config.CombatLogDuration or 45000
            TriggerClientEvent('luxury:client:combatLogMarker', -1, {
                coords = dropCoords,
                name = player.name,
                citizenid = player.citizenid,
                id = src,
                reason = tostring(reason or 'Desconexión'),
                duration = duration
            })
        end

        if Logger and Logger.LogConnection then
            Logger.LogConnection(player.name, player.license, 'Desconexión', ('CID: %s | Motivo: %s'):format(player.citizenid, tostring(reason or 'Desconocido')))
        end

        Core.UnloadPlayer(src, false)
        print(('^3[luxury_core]^7 Jugador guardado y desconectado: %s (ID: %d | %s)'):format(player.name, src, tostring(reason or 'Desconocido')))
    end
end)
