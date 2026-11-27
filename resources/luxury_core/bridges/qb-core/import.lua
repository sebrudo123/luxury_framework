-- luxury_core: QBCore Import Helper (0.00ms no bloqueante)
local function resolveQBCore()
    if rawget(_G, 'QBCore') and type(QBCore) == 'table' and QBCore.Functions then
        return QBCore
    end

    local ok, obj = pcall(function()
        return exports['luxury_core']:GetCoreObject()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        return obj
    end

    ok, obj = pcall(function()
        return exports['luxury_core']:GetQBCore()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        return obj
    end

    return nil
end

QBCore = resolveQBCore()

-- Resolución asíncrona en hilo separado para NUNCA bloquear el inicio del recurso
if not QBCore then
    CreateThread(function()
        local attempts = 0
        while not QBCore and attempts < 100 do
            Wait(100)
            attempts = attempts + 1
            QBCore = resolveQBCore()
        end
    end)
end
