-- luxury_lib: Motor de Proxy (Inter-Resource Proxy Engine)
Proxy = Proxy or {}
local interfaces = {}

--- Registra una interfaz de funciones accesibles por Proxy
-- @param name string: Nombre de la interfaz (ej: 'luxury', 'luxury_core')
-- @param itf table: Tabla con las funciones que componen la interfaz
function Proxy.addInterface(name, itf)
    interfaces[name] = itf
end

--- Obtiene un objeto Proxy para comunicarse con una interfaz
-- @param name string: Nombre de la interfaz
-- @return table: Proxy con auto-despacho dinámico (__index)
function Proxy.getInterface(name)
    local proxy = {}
    return setmetatable(proxy, {
        __index = function(self, key)
            -- 1) Si está en la misma memoria Lua del recurso, llamada directa instantánea (0 overhead)
            local iface = interfaces[name]
            if iface and iface[key] then
                return iface[key]
            end

            -- 2) Si se llama desde otro recurso, despacho dinámico a través del export ProxyCall
            local fn = function(...)
                return exports['luxury_core']:ProxyCall(name, key, ...)
            end
            self[key] = fn -- Cachear la función para acelerar futuras llamadas
            return fn
        end
    })
end

--- Realiza una llamada directa a una interfaz registrada
-- @param name string
-- @param method string
-- @param ... any
-- @return any
function Proxy.call(name, method, ...)
    local iface = interfaces[name]
    if iface and iface[method] then
        return iface[method](...)
    end
    error(('[^1PROXY ERROR^7] No existe el método %s en la interfaz %s'):format(tostring(method), tostring(name)))
end

exports('GetProxy', function() return Proxy end)
