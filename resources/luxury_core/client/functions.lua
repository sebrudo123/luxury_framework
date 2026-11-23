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

--- Dibuja texto tridimensional en el mundo del juego
-- @param x number
-- @param y number
-- @param z number
-- @param text string
-- @param r number|nil
-- @param g number|nil
-- @param b number|nil
-- @param a number|nil
function Functions.DrawText3D(x, y, z, text, r, g, b, a)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local camCoords = GetGameplayCamCoord()
    local dist = #(camCoords - vector3(x, y, z))
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.35 * scale, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(r or 255, g or 255, b or 255, a or 220)
    SetTextCentre(1)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(screenX, screenY)
end

---------------------------------------------------------------------
-- Sistema de Texto Flotante Sobre la Cabeza (/me y /do 3D)
---------------------------------------------------------------------
local activeOverheadTexts = {}

RegisterNetEvent('luxury:client:show3DText', function(targetServerId, text, msgType)
    local playerIdx = GetPlayerFromServerId(targetServerId)
    if playerIdx == -1 and targetServerId ~= GetPlayerServerId(PlayerId()) then return end

    local expiresAt = GetGameTimer() + 7000 -- 7 segundos de duración
    local color = msgType == 'do' and { 56, 189, 248, 240 } or { 192, 132, 252, 240 }
    local prefix = msgType == 'do' and '[DO] ' or '* '

    activeOverheadTexts[#activeOverheadTexts + 1] = {
        serverId = targetServerId,
        text = prefix .. text,
        color = color,
        expiresAt = expiresAt
    }
end)

CreateThread(function()
    while true do
        local sleep = 500
        local now = GetGameTimer()
        local count = #activeOverheadTexts

        if count > 0 then
            sleep = 0
            local localPed = PlayerPedId()
            local localCoords = GetEntityCoords(localPed)

            for i = count, 1, -1 do
                local entry = activeOverheadTexts[i]
                if now > entry.expiresAt then
                    table.remove(activeOverheadTexts, i)
                else
                    local playerIdx = GetPlayerFromServerId(entry.serverId)
                    local targetPed = playerIdx ~= -1 and GetPlayerPed(playerIdx) or (entry.serverId == GetPlayerServerId(PlayerId()) and localPed or nil)

                    if targetPed and DoesEntityExist(targetPed) then
                        local pedCoords = GetEntityCoords(targetPed)
                        local dist = #(localCoords - pedCoords)

                        if dist <= 20.0 then
                            local zOffset = 0.95 + (math.max(0, count - i) * 0.15)
                            Functions.DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + zOffset, entry.text, entry.color[1], entry.color[2], entry.color[3], entry.color[4])
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

exports('GetClosestPlayer', Functions.GetClosestPlayer)
exports('GetClosestVehicle', Functions.GetClosestVehicle)
exports('DrawText3D', Functions.DrawText3D)
