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

    -- Limpiar State Bags de muerte
    if type(Player) == 'function' and Player(src) and Player(src).state then Player(src).state:set('isDead', false, true) end

    -- Teletransportar al hospital
    TriggerClientEvent('luxury:client:hospitalRespawn', src, Config.HospitalCoords)
    print(('^3[luxury_core]^7 Jugador %s (ID: %d) reapareció en el hospital.'):format(player.name, src))
end)

-- Notificar estado de muerte al servidor
RegisterNetEvent('luxury:server:setDeadState', function(isDead)
    local src = source
    if type(Player) == 'function' and Player(src) and Player(src).state then Player(src).state:set('isDead', isDead, true) end
end)
