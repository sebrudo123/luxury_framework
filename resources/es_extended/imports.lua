local function getObject()
    local esx = nil
    pcall(function()
        esx = exports['luxury_core']:GetESX()
    end)
    return esx
end

ESX = getObject()
