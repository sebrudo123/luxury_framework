-- luxury_lib: Sistema de Callbacks (Servidor)
Luxury = Luxury or {}
Luxury.ServerCallbacks = {}
Luxury.PendingClientCallbacks = {}
local clientTicketCounter = 0

--- Registra un callback que el cliente puede invocar
-- @param name string: Nombre único del callback
-- @param cb function: Función que procesará la petición: function(src, responseCb, ...)
function Luxury.RegisterCallback(name, cb)
    Luxury.ServerCallbacks[name] = cb
end

-- Listener para cuando un cliente solicita un callback del servidor
RegisterNetEvent('luxury:lib:triggerServerCallback', function(ticket, name, ...)
    local src = source
    local handler = Luxury.ServerCallbacks[name]

    if not handler then
        print(('[^1ERROR^7] luxury_lib: Callback del servidor ^3%s^7 no registrado (solicitado por ID %d)'):format(name, src))
        TriggerClientEvent('luxury:lib:serverCallbackResponse', src, ticket, false)
        return
    end

    handler(src, function(...)
        TriggerClientEvent('luxury:lib:serverCallbackResponse', src, ticket, ...)
    end, ...)
end)

--- Dispara un callback hacia un cliente específico (con función callback)
-- @param src number: Source del jugador
-- @param name string: Nombre del callback en el cliente
-- @param cb function: Función receptora de la respuesta
function Luxury.TriggerClientCallback(src, name, cb, ...)
    clientTicketCounter = (clientTicketCounter + 1) % 1000000
    local ticket = clientTicketCounter
    Luxury.PendingClientCallbacks[ticket] = cb

    TriggerClientEvent('luxury:lib:triggerClientCallback', src, ticket, name, ...)

    -- Timeout de seguridad de 10 segundos
    SetTimeout(10000, function()
        if Luxury.PendingClientCallbacks[ticket] then
            Luxury.PendingClientCallbacks[ticket] = nil
        end
    end)
end

--- Dispara un callback hacia el cliente y espera su resolución (Sintaxis Await/Promesas)
-- @param src number: Source del jugador
-- @param name string: Nombre del callback
-- @return ...: Valores devueltos por el cliente
function Luxury.AwaitClientCallback(src, name, ...)
    local p = promise.new()
    Luxury.TriggerClientCallback(src, name, function(...)
        p:resolve({ ... })
    end, ...)
    local result = Citizen.Await(p)
    return table.unpack(result)
end

RegisterNetEvent('luxury:lib:clientCallbackResponse', function(ticket, ...)
    local cb = Luxury.PendingClientCallbacks[ticket]
    if cb then
        Luxury.PendingClientCallbacks[ticket] = nil
        cb(...)
    end
end)

-- Exports para facilitar el uso desde cualquier recurso
exports('RegisterCallback', Luxury.RegisterCallback)
exports('TriggerClientCallback', Luxury.TriggerClientCallback)
exports('AwaitClientCallback', Luxury.AwaitClientCallback)
