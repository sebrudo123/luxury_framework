-- luxury_core: Interfaz de Proxy y Tunnel del Cliente
Proxy = Proxy or {}
if not Proxy.addInterface then
    Proxy.addInterface = function(name, itf) end
end
Tunnel = Tunnel or {}
if not Tunnel.bindInterface then
    Tunnel.bindInterface = function(name, itf) end
end

local ClientInterface = {}

ClientInterface.GetPlayerData = function() return PlayerData end
ClientInterface.IsPlayerLoaded = function() return LocalPlayer.state.isLoggedIn or false end
ClientInterface.IsDead = function() return LocalPlayer.state.isDead or false end
ClientInterface.GetStatus = function()
    return {
        hunger = LocalPlayer.state.hunger or 100,
        thirst = LocalPlayer.state.thirst or 100
    }
end

ClientInterface.GetCache = function()
    return Luxury and Luxury.Cache or {}
end

ClientInterface.Notify = function(msg, notifyType, duration)
    if Luxury and Luxury.Notify then
        Luxury.Notify(msg, notifyType, duration)
    end
end

---------------------------------------------------------------------
-- Registro de Interfaces en Proxy y Tunnel (Cliente)
---------------------------------------------------------------------
Proxy.addInterface('luxury', ClientInterface)
Proxy.addInterface('luxury_core', ClientInterface)

Tunnel.bindInterface('luxury', ClientInterface)
Tunnel.bindInterface('luxury_core', ClientInterface)

exports('ProxyCall', function(interfaceName, methodName, ...)
    local iface = (interfaceName == 'luxury' or interfaceName == 'luxury_core') and ClientInterface or nil
    if iface and iface[methodName] then
        return iface[methodName](...)
    end
    error(('[^1PROXY ERROR^7] El método %s en la interfaz %s no existe en cliente'):format(tostring(methodName), tostring(interfaceName)))
end)

exports('GetProxy', function() return Proxy end)
exports('GetTunnel', function() return Tunnel end)
