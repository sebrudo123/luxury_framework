local function getQPlayer(src)
    return exports['luxury_core']:GetQboxPlayer(src)
end

exports('GetPlayer', getQPlayer)

exports('GetPlayerByCitizenId', function(cid)
    local qb = exports['luxury_core']:GetQBCore()
    return qb and qb.Functions and qb.Functions.GetPlayerByCitizenId(cid) or nil
end)

exports('GetPlayersData', function()
    return exports['luxury_core']:GetQboxPlayersData()
end)

exports('GetCoreObject', function()
    return exports['luxury_core']:GetQBCore()
end)

exports('Notify', function(src, text, notifyType, duration)
    TriggerClientEvent('qbx_core:client:notify', src, text, notifyType, duration)
end)

exports('AddMoney', function(src, account, amount, reason)
    local p = getQPlayer(src)
    return p and p.Functions and p.Functions.AddMoney(account, amount, reason) or false
end)

exports('RemoveMoney', function(src, account, amount, reason)
    local p = getQPlayer(src)
    return p and p.Functions and p.Functions.RemoveMoney(account, amount, reason) or false
end)

exports('SetJob', function(src, jobName, grade)
    local p = getQPlayer(src)
    return p and p.Functions and p.Functions.SetJob(jobName, grade) or false
end)

exports('SetGang', function(src, gangName, grade)
    local p = getQPlayer(src)
    return p and p.Functions and p.Functions.SetGang(gangName, grade) or false
end)

exports('SetJobDuty', function(src, onDuty)
    local p = getQPlayer(src)
    return p and p.Functions and p.Functions.SetJobDuty(onDuty) or false
end)
