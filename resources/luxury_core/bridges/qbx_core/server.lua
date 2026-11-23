exports('GetPlayer', function(src)
    return exports['luxury_core']:GetPlayer(src)
end)

exports('GetPlayerByCitizenId', function(cid)
    return exports['luxury_core']:GetPlayerByCitizenId(cid)
end)
