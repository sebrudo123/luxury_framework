-- luxury_core: QBX Import Helper (0.00ms no bloqueante)
local function resolveQBX()
    if rawget(_G, 'qbx') and type(qbx) == 'table' then
        return qbx
    end

    local ok, obj = pcall(function()
        return exports['luxury_core']:GetCoreObject()
    end)
    if ok and obj and type(obj) == 'table' then
        return obj
    end

    return nil
end

qbx = resolveQBX()
QBCore = resolveQBX()

-- Resolución asíncrona en hilo separado para NUNCA bloquear el inicio del recurso
if not qbx then
    CreateThread(function()
        local attempts = 0
        while not qbx and attempts < 100 do
            Wait(100)
            attempts = attempts + 1
            qbx = resolveQBX()
            QBCore = qbx
        end
    end)
end
