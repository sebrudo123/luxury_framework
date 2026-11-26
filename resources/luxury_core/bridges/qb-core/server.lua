-- luxury_core: Puente Servidor para scripts QBCore (exports['qb-core']:GetCoreObject())
local function getQBCoreObject()
    if rawget(_G, 'QBCore') and type(QBCore) == 'table' and QBCore.Functions then
        return QBCore
    end

    local ok, obj = pcall(function()
        return exports['luxury_core']:GetCoreObject()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        QBCore = obj
        return QBCore
    end

    ok, obj = pcall(function()
        return exports['luxury_core']:GetQBCore()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        QBCore = obj
        return QBCore
    end

    return QBCore
end

QBCore = getQBCoreObject()

AddEventHandler('QBCore:GetObject', function(cb)
    cb(getQBCoreObject())
end)

exports('GetCoreObject', getQBCoreObject)
exports('GetSharedObject', getQBCoreObject)
exports('GetQBCore', getQBCoreObject)
