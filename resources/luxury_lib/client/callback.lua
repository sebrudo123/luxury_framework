-- luxury_lib: Sistema de Callbacks (Cliente)
Luxury = Luxury or {}
Luxury.PendingServerCallbacks = {}
Luxury.ClientCallbacks = {}
local serverTicketCounter = 0

--- Dispara un callback del servidor con una función de retorno (asíncrono)
-- @param name string: Nombre del callback registrado en el servidor
-- @param cb function: Callback a ejecutar con la respuesta
function Luxury.TriggerCallback(name, cb, ...)
    serverTicketCounter = (serverTicketCounter + 1) % 1000000
    local ticket = serverTicketCounter
    Luxury.PendingServerCallbacks[ticket] = cb

    TriggerServerEvent('luxury:lib:triggerServerCallback', ticket, name, ...)

    -- Timeout de seguridad de 15 segundos
    SetTimeout(15000, function()
        if Luxury.PendingServerCallbacks[ticket] then
            Luxury.PendingServerCallbacks[ticket] = nil
            print(('[^1TIMEOUT^7] luxury_lib: Callback ^3%s^7 excedió el tiempo límite'):format(name))
        end
    end)
end

--- Dispara un callback del servidor y espera la respuesta sincrónicamente (Await)
-- @param name string: Nombre del callback registrado en el servidor
-- @return ...: Argumentos de respuesta devueltos por el servidor
function Luxury.AwaitCallback(name, ...)
    local p = promise.new()
    Luxury.TriggerCallback(name, function(...)
        p:resolve({ ... })
    end, ...)
    local result = Citizen.Await(p)
    return table.unpack(result)
end

--- Registra un callback en el cliente que el servidor puede invocar
-- @param name string: Nombre del callback
-- @param cb function: Función receptora: function(responseCb, ...)
function Luxury.RegisterClientCallback(name, cb)
    Luxury.ClientCallbacks[name] = cb
end

RegisterNetEvent('luxury:lib:serverCallbackResponse', function(ticket, ...)
    local cb = Luxury.PendingServerCallbacks[ticket]
    if cb then
        Luxury.PendingServerCallbacks[ticket] = nil
        cb(...)
    end
end)

RegisterNetEvent('luxury:lib:triggerClientCallback', function(ticket, name, ...)
    local handler = Luxury.ClientCallbacks[name]
    if not handler then
        TriggerServerEvent('luxury:lib:clientCallbackResponse', ticket, false)
        return
    end

    handler(function(...)
        TriggerServerEvent('luxury:lib:clientCallbackResponse', ticket, ...)
    end, ...)
end)

exports('TriggerCallback', Luxury.TriggerCallback)
exports('AwaitCallback', Luxury.AwaitCallback)
exports('RegisterClientCallback', Luxury.RegisterClientCallback)
