QBCore = nil

local function getQBCore()
    if not QBCore then
        pcall(function()
            QBCore = exports['luxury_core']:GetQBCore()
        end)
    end
    return QBCore
end

QBCore = getQBCore()

AddEventHandler('QBCore:GetObject', function(cb)
    cb(getQBCore())
end)

exports('GetCoreObject', function()
    return getQBCore()
end)

exports('GetSharedObject', function()
    return getQBCore()
end)

exports('GetQBCore', function()
    return getQBCore()
end)
