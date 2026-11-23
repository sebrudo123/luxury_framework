-- luxury_core: Funciones de Utilidad del Cliente (Client Functions)
Functions = {}

--- Obtiene el jugador más cercano a las coordenadas del ped local
-- @param maxDistance number|nil: Distancia máxima (por defecto 3.0 metros)
-- @return number, number: serverId del jugador (-1 si no hay) y distancia
function Functions.GetClosestPlayer(maxDistance)
    maxDistance = maxDistance or 3.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestPlayer, closestDist = -1, -1

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local dist = #(coords - GetEntityCoords(targetPed))
            if dist <= maxDistance and (closestDist == -1 or dist < closestDist) then
                closestPlayer = GetPlayerServerId(playerId)
                closestDist = dist
            end
        end
    end

    return closestPlayer, closestDist
end

--- Obtiene el vehículo más cercano al ped local
-- @param maxDistance number|nil (por defecto 5.0 metros)
-- @return number, number: handle de la entidad del vehículo y distancia
function Functions.GetClosestVehicle(maxDistance)
    maxDistance = maxDistance or 5.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, maxDistance + 0.0, 0, 71)

    if veh and veh ~= 0 and DoesEntityExist(veh) then
        return veh, #(coords - GetEntityCoords(veh))
    end
    return 0, -1
end

exports('GetClosestPlayer', Functions.GetClosestPlayer)
exports('GetClosestVehicle', Functions.GetClosestVehicle)
