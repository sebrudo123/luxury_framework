-- luxury_core: Puente de Compatibilidad con QBCore (Servidor)
QBCore = QBCore or {}
QBCore.Functions = {}
QBCore.ServerCallbacks = {}
QBCore.Shared = {
    Jobs = Jobs,
    Items = {}
}

---------------------------------------------------------------------
-- Wrapper / Adaptador QPlayer de QBCore
---------------------------------------------------------------------
local function buildQPlayer(player)
    local self = {}
    self.PlayerData = {
        source = player.source,
        citizenid = player.citizenid,
        license = player.license,
        name = player.name,
        charinfo = player.charinfo,
        money = {
            cash = player.cash,
            bank = player.bank,
            crypto = 0
        },
        job = {
            name = player.job.name,
            label = player.job.label,
            payment = player.job.salary,
            onduty = true,
            isboss = player.job.isBoss,
            grade = {
                level = player.job.grade,
                name = player.job.grade_label
            }
        },
        gang = {
            name = 'none',
            label = 'Ninguna',
            isboss = false,
            grade = { level = 0, name = 'none' }
        },
        metadata = {
            hunger = player.needs.hunger,
            thirst = player.needs.thirst,
            isdead = false,
            inlaststand = false
        },
        items = player:getInventory() or {}
    }

    self.Functions = {}

    function self.Functions.GetMoney(account)
        return player:getMoney(account)
    end

    function self.Functions.AddMoney(account, amount, reason)
        return player:addMoney(account, amount)
    end

    function self.Functions.RemoveMoney(account, amount, reason)
        return player:removeMoney(account, amount)
    end

    function self.Functions.SetMoney(account, amount, reason)
        return player:setMoney(account, amount)
    end

    function self.Functions.GetItemByName(item)
        return player:getItem(item)
    end

    function self.Functions.GetItemsByName(item)
        local i = player:getItem(item)
        return i and { i } or {}
    end

    function self.Functions.AddItem(item, amount, slot, info)
        return player:addItem(item, amount, info, slot)
    end

    function self.Functions.RemoveItem(item, amount, slot)
        return player:removeItem(item, amount, nil, slot)
    end

    function self.Functions.SetJob(jobName, grade)
        return player:setJob(jobName, grade)
    end

    function self.Functions.SetGang(gangName, grade)
        self.PlayerData.gang.name = gangName
        self.PlayerData.gang.grade.level = tonumber(grade) or 0
        return true
    end

    function self.Functions.SetMetaData(key, val)
        self.PlayerData.metadata[key] = val
        if key == 'hunger' then player:setNeed('hunger', val) end
        if key == 'thirst' then player:setNeed('thirst', val) end
        return true
    end

    function self.Functions.GetMetaData(key)
        return self.PlayerData.metadata[key]
    end

    function self.Functions.Save()
        player:save(true)
    end

    return self
end

---------------------------------------------------------------------
-- Funciones Globales del Servidor QBCore
---------------------------------------------------------------------
function QBCore.Functions.GetPlayer(src)
    local player = Core.Players[tonumber(src)]
    return player and buildQPlayer(player) or nil
end

function QBCore.Functions.GetPlayerByCitizenId(cid)
    local player = exports.luxury_core:GetPlayerByCitizenId(cid)
    return player and buildQPlayer(player) or nil
end

function QBCore.Functions.GetPlayerByPhone(phone)
    for _, player in pairs(Core.Players) do
        if player.charinfo and player.charinfo.phone == phone then
            return buildQPlayer(player)
        end
    end
    return nil
end

function QBCore.Functions.GetPlayers()
    local sources = {}
    for src, _ in pairs(Core.Players) do
        sources[#sources + 1] = src
    end
    return sources
end

function QBCore.Functions.CreateCallback(name, cb)
    QBCore.ServerCallbacks[name] = cb
    if Luxury and Luxury.RegisterCallback then
        Luxury.RegisterCallback(name, cb)
    end
end

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, ...)
    local src = source
    local cb = QBCore.ServerCallbacks[name]
    if cb then
        cb(src, function(...)
            TriggerClientEvent('QBCore:Client:CallbackResponse', src, name, ...)
        end, ...)
    end
end)

function QBCore.Functions.Notify(src, text, notifyType, length)
    TriggerClientEvent('QBCore:Notify', src, text, notifyType, length)
end

-- Handlers de evento clásicos
AddEventHandler('QBCore:GetObject', function(cb)
    cb(QBCore)
end)

-- Exports compatibles con QBCore
exports('GetCoreObject', function() return QBCore end)
exports('GetSharedObject', function() return QBCore end)
exports('GetQBCore', function() return QBCore end)
