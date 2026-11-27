-- luxury_core: Puente Servidor para scripts ESX Legacy y Modernos
local function getESXObject()
    if rawget(_G, 'ESX') and type(ESX) == 'table' and ESX.GetPlayerFromId then
        return ESX
    end

    local ok, obj = pcall(function()
        return exports['luxury_core']:getSharedObject()
    end)
    if ok and obj and type(obj) == 'table' then
        ESX = obj
        return ESX
    end

    ok, obj = pcall(function()
        return exports['luxury_core']:GetSharedObject()
    end)
    if ok and obj and type(obj) == 'table' then
        ESX = obj
        return ESX
    end

    ok, obj = pcall(function()
        return exports['luxury_core']:GetESX()
    end)
    if ok and obj and type(obj) == 'table' then
        ESX = obj
        return ESX
    end

    return ESX
end

ESX = getESXObject()

AddEventHandler('esx:getSharedObject', function(cb)
    cb(getESXObject())
end)

exports('getSharedObject', getESXObject)
exports('GetSharedObject', getESXObject)
exports('GetESX', getESXObject)
