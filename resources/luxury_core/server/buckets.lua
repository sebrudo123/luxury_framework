-- luxury_core: Gestor de Dimensiones e Instancias (OneSync Routing Buckets)
Buckets = {}

--- Asigna una dimensión / instancia (Routing Bucket) a un jugador
-- @param src number: Source del jugador
-- @param bucket number|nil: ID del bucket (0 para el mundo principal)
-- @return boolean
function SetPlayerBucket(src, bucket)
    src = tonumber(src)
    bucket = tonumber(bucket) or 0

    if not src or not GetPlayerPing(src) or GetPlayerPing(src) <= 0 then
        return false
    end

    SetPlayerRoutingBucket(src, bucket)
    if type(Player) == 'function' and Player(src) and Player(src).state then Player(src).state:set('instance', bucket, true) end
    return true
end

--- Obtiene la dimensión / instancia actual del jugador
-- @param src number
-- @return number
function GetPlayerBucket(src)
    src = tonumber(src)
    if not src then return 0 end
    return GetPlayerRoutingBucket(src) or 0
end

--- Devuelve al jugador al mundo principal (Bucket 0)
-- @param src number
-- @return boolean
function ResetPlayerBucket(src)
    return SetPlayerBucket(src, 0)
end

-- Exports
exports('SetPlayerBucket', SetPlayerBucket)
exports('GetPlayerBucket', GetPlayerBucket)
exports('ResetPlayerBucket', ResetPlayerBucket)
