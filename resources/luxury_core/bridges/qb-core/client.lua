QBCore = exports['luxury_core']:GetQBCore()

AddEventHandler('QBCore:GetObject', function(cb)
    cb(QBCore)
end)

exports('GetCoreObject', function() return QBCore end)
exports('GetSharedObject', function() return QBCore end)
exports('GetQBCore', function() return QBCore end)
