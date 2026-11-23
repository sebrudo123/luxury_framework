-- luxury_core: Manejadores de Eventos de Red del Servidor (Server Events)

-- Solicitud de carga inicial del jugador
RegisterNetEvent('luxury:server:requestLoad', function()
    local src = source
    if Security and not Security.CheckRateLimit(src) then return end

    if not Core.Players[src] then
        Core.LoadPlayer(src)
    end
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

-- Desconexión de un jugador
AddEventHandler('playerDropped', function()
    local src = source
    local player = Core.Players[src]

    if player then
        local ped = GetPlayerPed(src)
        if ped and DoesEntityExist(ped) then
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            player:setCoords({ x = pos.x, y = pos.y, z = pos.z, heading = heading })
        end

        player:save(false)
        Core.Players[src] = nil

        -- Eventos de compatibilidad
        TriggerEvent('esx:playerDropped', src)
        TriggerEvent('QBCore:Server:OnPlayerUnload', src)
        TriggerClientEvent('QBCore:Client:OnPlayerUnload', src)

        print(('^3[luxury_core]^7 Jugador guardado y desconectado: %s (ID: %d)'):format(player.name, src))
    end
end)
