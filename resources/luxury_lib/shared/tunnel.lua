-- luxury_lib: Motor de Tunnel (Network RPC Proxy con Promesas y Await)
Tunnel = Tunnel or {}
local boundInterfaces = {}
local pendingCalls = {}
local ticketCounter = 0

local isServer = IsDuplicityVersion()

--- Publica una interfaz de funciones a través del Tunnel de red
-- @param name string: Nombre de la interfaz de red
-- @param itf table: Tabla de funciones
function Tunnel.bindInterface(name, itf)
    boundInterfaces[name] = itf
end

--- Obtiene una interfaz de red como Proxy
-- Permite invocar funciones remotas con sintaxis síncrona/Await sin callbacks anidados
-- @param name string: Nombre de la interfaz remota
-- @return table: Proxy de Tunnel
function Tunnel.getInterface(name)
    local tunnelProxy = {}
    return setmetatable(tunnelProxy, {
        __index = function(self, key)
            local fn = function(...)
                ticketCounter = (ticketCounter + 1) % 1000000
                local ticket = ticketCounter
                local p = promise.new()
                pendingCalls[ticket] = p

                if isServer then
                    -- Servidor llamando a Cliente: primer parámetro debe ser el targetSrc
                    local args = { ... }
                    local targetSrc = table.remove(args, 1)
                    TriggerClientEvent('luxury:tunnel:serverToClient', targetSrc, ticket, name, key, table.unpack(args))
                else
                    -- Cliente llamando a Servidor
                    TriggerServerEvent('luxury:tunnel:clientToServer', ticket, name, key, ...)
                end

                -- Timeout de seguridad de 10 segundos
                SetTimeout(10000, function()
                    if pendingCalls[ticket] then
                        pendingCalls[ticket] = nil
                        p:resolve({ false, 'TIMEOUT' })
                    end
                end)

                local res = Citizen.Await(p)
                return table.unpack(res)
            end
            self[key] = fn
            return fn
        end
    })
end

---------------------------------------------------------------------
-- Manejadores de Red para el Tunnel
---------------------------------------------------------------------
if isServer then
    -- Servidor recibe petición del Cliente
    RegisterNetEvent('luxury:tunnel:clientToServer', function(ticket, interfaceName, methodName, ...)
        local src = source
        local iface = boundInterfaces[interfaceName]
        if iface and iface[methodName] then
            local results = { pcall(iface[methodName], src, ...) }
            local success = table.remove(results, 1)
            if success then
                TriggerClientEvent('luxury:tunnel:response', src, ticket, results)
            else
                print(('[^1TUNNEL ERROR^7] Fallo ejecutando %s.%s: %s'):format(interfaceName, methodName, tostring(results[1])))
                TriggerClientEvent('luxury:tunnel:response', src, ticket, { false })
            end
        else
            TriggerClientEvent('luxury:tunnel:response', src, ticket, { false })
        end
    end)
else
    -- Cliente recibe petición del Servidor
    RegisterNetEvent('luxury:tunnel:serverToClient', function(ticket, interfaceName, methodName, ...)
        local iface = boundInterfaces[interfaceName]
        if iface and iface[methodName] then
            local results = { pcall(iface[methodName], ...) }
            local success = table.remove(results, 1)
            TriggerServerEvent('luxury:tunnel:response', ticket, success and results or { false })
        else
            TriggerServerEvent('luxury:tunnel:response', ticket, { false })
        end
    end)
end

-- Recepción de respuesta común (Cliente o Servidor)
RegisterNetEvent('luxury:tunnel:response', function(ticket, results)
    local p = pendingCalls[ticket]
    if p then
        pendingCalls[ticket] = nil
        p:resolve(results)
    end
end)

exports('GetTunnel', function() return Tunnel end)
