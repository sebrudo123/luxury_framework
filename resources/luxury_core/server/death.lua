-- luxury_core: Sistema de Muerte, Hospital y Reaparición (Servidor)

--- Manejo de reaparición tras coma médico (Bleedout)
RegisterNetEvent('luxury:server:respawnAtHospital', function()
    local src = source
    local player = Core.Players[src]
    if not player then return end

    -- Cobrar factura médica del hospital si tiene saldo
    local fee = Config.HospitalFee or 250
    if player.bank >= fee then
        player:removeMoney('bank', fee)
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^3[Hospital]^7', ('Se te han cobrado ^1$%d^7 de tu cuenta bancaria por la atención médica.'):format(fee) }
        })
    else
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^3[Hospital]^7', 'La atención médica ha sido cubierta por la seguridad social.' }
        })
    end

    -- Limpiar State Bags y Metadata de muerte
    player:setMetadata('isdead', false)
    player:setMetadata('inlaststand', false)
    if type(Player) == 'function' and Player(src) and Player(src).state then Player(src).state:set('isDead', false, true) end

    -- Teletransportar al hospital
    TriggerClientEvent('luxury:client:hospitalRespawn', src, Config.HospitalCoords)
    print(('^3[luxury_core]^7 Jugador %s (ID: %d) reapareció en el hospital.'):format(player.name, src))
end)

-- Notificar estado de muerte al servidor y registrar Kill Log en Discord
RegisterNetEvent('luxury:server:setDeadState', function(isDead, killerId, weaponHash)
    local src = source
    local player = Core.Players[src]
    if not player then return end

    local deadBool = isDead == true
    player:setMetadata('isdead', deadBool)
    if type(Player) == 'function' and Player(src) and Player(src).state then
        Player(src).state:set('isDead', deadBool, true)
    end

    if deadBool and Logger and Logger.LogDeath then
        local killer = killerId and tonumber(killerId) and Core.Players[tonumber(killerId)] or nil
        local dist = nil
        if killer then
            local vPed = GetPlayerPed(src)
            local kPed = GetPlayerPed(killer.source)
            if vPed ~= 0 and kPed ~= 0 and DoesEntityExist(vPed) and DoesEntityExist(kPed) then
                dist = #(GetEntityCoords(vPed) - GetEntityCoords(kPed))
            end
        end
        Logger.LogDeath(
            player.name,
            player.license,
            killer and killer.name or nil,
            killer and killer.license or nil,
            weaponHash and tostring(weaponHash) or 'Entorno',
            dist
        )
    end
end)
