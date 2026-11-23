-- luxury_lib: Inicializador y exportador global

Luxury = Luxury or {}
Luxury.Math = Luxury.Math or {}
Luxury.Table = Luxury.Table or {}
Luxury.Cache = Luxury.Cache or {}
Luxury.Streaming = Luxury.Streaming or {}
Luxury.Proxy = Proxy
Luxury.Tunnel = Tunnel

-- Exportador principal
exports('GetLib', function()
    return Luxury
end)

exports('GetProxy', function()
    return Proxy
end)

exports('GetTunnel', function()
    return Tunnel
end)

exports('GetVersion', function()
    return '1.3.0'
end)
