-- luxury_core: Motor de Túnel RPC Asíncrono (Network RPC Tunnel Engine)
Tunnel = Tunnel or {}

local isServer = IsDuplicityVersion()
local interfaces = {}
local callbacks = {}
local callbackId = 0

--- Enlaza una interfaz al motor de Tunnel para llamadas remotas RPC
function Tunnel.bindInterface(name, itf)
    interfaces[name] = itf
end

--- Obtiene una interfaz remota para invocar métodos RPC
function Tunnel.getInterface(name)
    local tunnel = {}
    return setmetatable(tunnel, {
        __index = function(self, key)
            local fn = function(...)
                local args = { ... }
                local p = promise.new()
                callbackId = callbackId + 1
                local curId = callbackId

                callbacks[curId] = function(...)
                    p:resolve(...)
                end

                if isServer then
                    local target = table.remove(args, 1)
                    TriggerClientEvent('luxury_tunnel:client:call', target, name, key, curId, args)
                else
                    TriggerServerEvent('luxury_tunnel:server:call', name, key, curId, args)
                end

                SetTimeout(10000, function()
                    if callbacks[curId] then
                        callbacks[curId] = nil
                        p:reject('Tunnel RPC Timeout (10s)')
                    end
                end)

                return Citizen.Await(p)
            end

            self[key] = fn
            return fn
        end
    })
end

-- Despacho de Eventos en Servidor
if isServer then
    RegisterNetEvent('luxury_tunnel:server:call', function(name, method, id, args)
        local src = source
        local iface = interfaces[name]
        if iface and iface[method] then
            local res = { iface[method](src, table.unpack(args)) }
            TriggerClientEvent('luxury_tunnel:client:res', src, id, res)
        end
    end)

    RegisterNetEvent('luxury_tunnel:server:res', function(id, res)
        if callbacks[id] then
            callbacks[id](table.unpack(res))
            callbacks[id] = nil
        end
    end)
else
    -- Despacho de Eventos en Cliente
    RegisterNetEvent('luxury_tunnel:client:call', function(name, method, id, args)
        local iface = interfaces[name]
        if iface and iface[method] then
            local res = { iface[method](table.unpack(args)) }
            TriggerServerEvent('luxury_tunnel:server:res', id, res)
        end
    end)

    RegisterNetEvent('luxury_tunnel:client:res', function(id, res)
        if callbacks[id] then
            callbacks[id](table.unpack(res))
            callbacks[id] = nil
        end
    end)
end

exports('GetTunnel', function() return Tunnel end)
