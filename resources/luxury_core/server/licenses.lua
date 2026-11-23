-- luxury_core: Sistema de Licencias de Personaje (Licenses System)
Licenses = {}

--- Comprueba si un jugador tiene una licencia activa
-- @param src number
-- @param licenseType string: 'driver', 'weapon', 'hunting', 'pilot'
-- @return boolean
function HasLicense(src, licenseType)
    local player = Core.Players[tonumber(src)]
    if not player then return false end
    return player:hasLicense(licenseType)
end

--- Otorga una licencia a un jugador
-- @param src number
-- @param licenseType string
-- @return boolean
function GrantLicense(src, licenseType)
    local player = Core.Players[tonumber(src)]
    if not player then return false end
    return player:grantLicense(licenseType)
end

--- Revoca una licencia a un jugador
-- @param src number
-- @param licenseType string
-- @return boolean
function RevokeLicense(src, licenseType)
    local player = Core.Players[tonumber(src)]
    if not player then return false end
    return player:revokeLicense(licenseType)
end

-- Exports
exports('HasLicense', HasLicense)
exports('GrantLicense', GrantLicense)
exports('RevokeLicense', RevokeLicense)
