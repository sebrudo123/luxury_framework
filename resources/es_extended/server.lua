ESX = nil

local function getESX()
    if not ESX then
        pcall(function()
            ESX = exports['luxury_core']:GetESX()
        end)
    end
    return ESX
end

ESX = getESX()

AddEventHandler('esx:getSharedObject', function(cb)
    cb(getESX())
end)

exports('getSharedObject', function()
    return getESX()
end)

exports('GetSharedObject', function()
    return getESX()
end)
