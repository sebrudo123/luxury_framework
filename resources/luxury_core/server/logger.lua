-- luxury_core: Sistema de Logs y Auditoría con Discord Webhooks
Logger = {}

local Colors = {
    Red = 16711680,      -- Sanciones / Baneos
    Orange = 16744192,   -- Alertas / Centinela
    Green = 65280,       -- Economía / Ingresos
    Blue = 255,          -- Comandos Admin
    Purple = 10181046    -- Facciones / General
}

--- Envía un embed formateado a Discord a través de HTTP
-- @param webhookUrl string
-- @param title string
-- @param description string
-- @param color number
-- @param fields table|nil
function Logger.SendWebhook(webhookUrl, title, description, color, fields)
    if not webhookUrl or webhookUrl == '' or not webhookUrl:find('http') then return end

    local embed = {
        {
            title = title,
            description = description,
            color = color or Colors.Blue,
            fields = fields or {},
            footer = {
                text = 'Luxury Security Sentinel • ' .. os.date('%Y-%m-%d %H:%M:%S'),
                icon_url = 'https://i.imgur.com/8Qe7KkE.png'
            }
        }
    }

    PerformHttpRequest(webhookUrl, function(statusCode, text, headers) end, 'POST', json.encode({
        username = 'Luxury Core Sentinel',
        avatar_url = 'https://i.imgur.com/8Qe7KkE.png',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

--- Registra un baneo HWID en Discord y en base de datos
function Logger.LogBan(name, license, reason, author, expireStr, ip)
    local fields = {
        { name = '👤 Jugador', value = name, inline = true },
        { name = '🆔 Licencia', value = license, inline = true },
        { name = '🌐 Dirección IP', value = ip or 'Oculta', inline = true },
        { name = '⚖️ Autor', value = author, inline = true },
        { name = '⏳ Duración', value = expireStr or 'Permanente', inline = true },
        { name = '🛡️ Motivo de Sanción', value = '```' .. reason .. '```', inline = false }
    }
    Logger.SendWebhook(Webhooks and Webhooks.Bans, '⛔ NUEVO BANEO HWID APLICADO', 'Un infractor ha sido expulsado y sancionado por hardware.', Colors.Red, fields)
end

--- Registra una alerta o flag del Centinela
function Logger.LogAnticheat(src, flagReason, details)
    local player = Core.Players[src]
    local name = player and player.name or GetPlayerName(src) or 'Desconocido'
    local license = player and player.license or 'N/A'

    local fields = {
        { name = '👤 Jugador', value = ('%s (ID: %d)'):format(name, src), inline = true },
        { name = '🆔 Licencia', value = license, inline = true },
        { name = '⚠️ Detección', value = flagReason, inline = false }
    }
    if details then
        fields[#fields + 1] = { name = '🔍 Detalles Técnicos', value = '```' .. details .. '```', inline = false }
    end

    Logger.SendWebhook(Webhooks and Webhooks.Anticheat, '🚨 ALERTA CENTINELA ANTI-CHEAT', 'Detección de comportamiento anómalo o inyección de memoria.', Colors.Orange, fields)
end

--- Registra uso de comandos administrativos
function Logger.LogAdminCommand(src, commandName, args)
    local player = Core.Players[src]
    local name = src == 0 and 'Consola' or (player and player.name or GetPlayerName(src))
    local argText = #args > 0 and table.concat(args, ' ') or 'Sin argumentos'

    local fields = {
        { name = '👮 Administrador', value = ('%s (ID: %d)'):format(name, src), inline = true },
        { name = '⌨️ Comando', value = '/' .. commandName, inline = true },
        { name = '📝 Parámetros', value = '```' .. argText .. '```', inline = false }
    }
    Logger.SendWebhook(Webhooks and Webhooks.Admin, '🛠️ COMANDO ADMINISTRATIVO EJECUTADO', 'Registro de auditoría de moderación.', Colors.Blue, fields)
end

--- Registra conexiones y desconexiones de jugadores
function Logger.LogConnection(name, license, action, reason)
    local fields = {
        { name = 'Jugador', value = tostring(name or 'Desconocido'), inline = true },
        { name = 'Licencia', value = tostring(license or 'N/A'), inline = true },
        { name = 'Evento', value = tostring(action or 'N/A'), inline = true }
    }
    if reason and reason ~= '' then
        fields[#fields + 1] = { name = 'Detalle', value = '```' .. tostring(reason) .. '```', inline = false }
    end
    local color = action == 'Desconexión' and Colors.Orange or Colors.Green
    Logger.SendWebhook(Webhooks and Webhooks.Connections, 'REGISTRO DE CONEXIÓN', 'Movimiento de sesión en el servidor.', color, fields)
end

--- Registra muertes y bajas entre jugadores o por entorno
function Logger.LogDeath(victimName, victimLicense, killerName, killerLicense, weaponName, distance)
    local fields = {
        { name = 'Víctima', value = ('%s (%s)'):format(victimName or 'N/A', victimLicense or 'N/A'), inline = false },
        { name = 'Atacante', value = killerName and ('%s (%s)'):format(killerName, killerLicense or 'N/A') or 'Entorno / Caída / Suicidio', inline = false },
        { name = 'Arma / Causa', value = tostring(weaponName or 'Desconocida'), inline = true },
        { name = 'Distancia', value = distance and ('%.1fm'):format(distance) or 'N/A', inline = true }
    }
    Logger.SendWebhook(Webhooks and Webhooks.Deaths, 'REGISTRO DE MUERTE', 'Incidente médico / combate registrado.', Colors.Red, fields)
end

--- Registra movimientos económicos auditados
function Logger.LogEconomy(src, account, amount, action, details)
    local player = Core.Players[src]
    local name = src == 0 and 'Sistema' or (player and player.name or GetPlayerName(src) or 'Desconocido')
    local fields = {
        { name = 'Jugador', value = ('%s (ID: %s)'):format(name, tostring(src)), inline = true },
        { name = 'Cuenta', value = tostring(account), inline = true },
        { name = 'Monto', value = ('$%s'):format(tostring(amount)), inline = true },
        { name = 'Operación', value = tostring(action), inline = false }
    }
    if details then
        fields[#fields + 1] = { name = 'Detalles', value = '```' .. tostring(details) .. '```', inline = false }
    end
    Logger.SendWebhook(Webhooks and Webhooks.Money, 'AUDITORÍA ECONÓMICA', 'Transacción registrada en el núcleo.', Colors.Green, fields)
end

--- Registra mensajes de chat RP y redes sociales
function Logger.LogChat(src, channel, msg)
    local player = Core.Players[src]
    local name = player and player.name or GetPlayerName(src) or 'Desconocido'
    local fields = {
        { name = 'Jugador', value = ('%s (ID: %d | %s)'):format(name, src, player and player.citizenid or 'N/A'), inline = true },
        { name = 'Canal', value = tostring(channel), inline = true },
        { name = 'Mensaje', value = '```' .. tostring(msg) .. '```', inline = false }
    }
    Logger.SendWebhook(Webhooks and Webhooks.Chat, 'REGISTRO DE CHAT RP', 'Actividad de conversación y roleplay.', Colors.Purple, fields)
end

--- Registra reportes enviados por jugadores al staff
function Logger.LogReport(src, msg)
    local player = Core.Players[src]
    local name = player and player.name or GetPlayerName(src) or 'Desconocido'
    local fields = {
        { name = 'Reportante', value = ('%s (ID: %d | %s)'):format(name, src, player and player.license or 'N/A'), inline = false },
        { name = 'Descripción', value = '```' .. tostring(msg) .. '```', inline = false }
    }
    Logger.SendWebhook(Webhooks and Webhooks.Reports, 'NUEVO REPORTE DE JUGADOR', 'Solicitud de asistencia administrativa.', Colors.Orange, fields)
end

exports('LogBan', Logger.LogBan)
exports('LogAnticheat', Logger.LogAnticheat)
exports('LogAdminCommand', Logger.LogAdminCommand)
exports('LogConnection', Logger.LogConnection)
exports('LogDeath', Logger.LogDeath)
exports('LogEconomy', Logger.LogEconomy)
exports('LogChat', Logger.LogChat)
exports('LogReport', Logger.LogReport)
