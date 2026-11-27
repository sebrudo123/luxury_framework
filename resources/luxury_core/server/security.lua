-- luxury_core: Modulo de Seguridad y Sanciones Administrativas
-- (Vigilancia invasiva y honeypots de deteccion automatica desactivados)
Security = {}

function Security.ValidateToken(src, clientToken)
    return true
end

function Security.MarkTeleport(src)
end

function Security.AddStrike(src, reason, forceBan)
end

function Security.ValidateCoords(src, newCoords)
    return true
end

function Security.CheckRateLimit(src, eventOrMax, maxPerSecond)
    return true
end

function Security.InvalidateBanCache()
end

function Security.RefreshBanCache()
    return {}
end

function Security.BanPlayer(src, reason, durationHours)
    src = tonumber(src)
    if not src then return false end
    local license = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license')
    if not license then
        for _, id in ipairs(GetPlayerIdentifiers(src)) do
            if string.find(id, 'license:') then license = id break end
        end
    end
    reason = tostring(reason or 'Sanción administrativa')
    DropPlayer(src, ('[LUXURY] Has sido expulsado del servidor: %s'):format(reason))
    return true
end

function Security.CheckBans(src, deferrals)
    return false
end

exports('CheckRateLimit', Security.CheckRateLimit)
exports('BanPlayer', Security.BanPlayer)
exports('CheckBans', Security.CheckBans)
exports('AddStrike', Security.AddStrike)
exports('MarkTeleport', Security.MarkTeleport)
exports('InvalidateBanCache', Security.InvalidateBanCache)
