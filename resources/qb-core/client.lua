-- luxury_core: Puente Cliente para scripts QBCore (exports['qb-core']:GetCoreObject())
QBCore = QBCore or {}

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

-- Fallback asíncrono para scripts de inicio rápido
if not (QBCore and QBCore.Functions) then
    CreateThread(function()
        local attempts = 0
        while not (QBCore and QBCore.Functions) and attempts < 100 do
            Wait(100)
            attempts = attempts + 1
            QBCore = getQBCoreObject()
        end
    end)
end

AddEventHandler('QBCore:GetObject', function(cb)
    cb(getQBCoreObject())
end)

exports('GetCoreObject', getQBCoreObject)
exports('GetSharedObject', getQBCoreObject)
exports('GetQBCore', getQBCoreObject)
