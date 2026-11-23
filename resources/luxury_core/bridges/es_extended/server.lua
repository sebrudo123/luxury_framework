ESX = exports['luxury_core']:GetESX()

AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

exports('getSharedObject', function() return ESX end)
exports('GetSharedObject', function() return ESX end)
