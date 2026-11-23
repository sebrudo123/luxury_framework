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

exports('LogBan', Logger.LogBan)
exports('LogAnticheat', Logger.LogAnticheat)
exports('LogAdminCommand', Logger.LogAdminCommand)
