-- luxury_core: Sistema de Necesidades (Hambre y Sed - Servidor)

--- Añadir o recuperar porcentaje de hambre o sed (por ejemplo al consumir comida o bebida)
-- @param src number: Source del jugador
-- @param need string: 'hunger' o 'thirst'
-- @param amount number: Cantidad a sumar (0 a 100)
-- @return boolean
function AddNeed(src, need, amount)
    local player = Core.Players[src]
    if not player or (need ~= 'hunger' and need ~= 'thirst') then return false end
    return player:addNeed(need, amount)
end

--- Reducir porcentaje de hambre o sed
-- @param src number
-- @param need string
-- @param amount number
-- @return boolean
function RemoveNeed(src, need, amount)
    local player = Core.Players[src]
    if not player or (need ~= 'hunger' and need ~= 'thirst') then return false end
    return player:removeNeed(need, amount)
end

--- Consultar porcentaje actual
-- @param src number
-- @param need string
-- @return number
function GetNeed(src, need)
    local player = Core.Players[src]
    if not player then return 0 end
    return player:getNeed(need)
end

-- Bucle de desgaste de hambre y sed
CreateThread(function()
    while true do
        Wait(Config.Status.TickInterval or 60000)
        for _, player in pairs(Core.Players) do
            player:removeNeed('hunger', Config.Status.HungerRate or 0.5)
            player:removeNeed('thirst', Config.Status.ThirstRate or 0.8)
        end
    end
end)

-- Evento de consumo directo desde cliente u ox_inventory
RegisterNetEvent('luxury:server:consumeNeed', function(need, amount)
    local src = source
    AddNeed(src, need, amount)
end)

exports('AddNeed', AddNeed)
exports('RemoveNeed', RemoveNeed)
exports('GetNeed', GetNeed)
