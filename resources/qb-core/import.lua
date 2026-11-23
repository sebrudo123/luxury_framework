local function getObject()
    local qb = nil
    pcall(function()
        qb = exports['luxury_core']:GetQBCore()
    end)
    return qb
end

QBCore = getObject()
