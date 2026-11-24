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
    local meta = player.metadata or {}
    self.PlayerData = {
        source = player.source,
        citizenid = player.citizenid,
        license = player.license,
        name = player.name,
        charinfo = player.charinfo,
        money = {
            cash = player.cash,
            bank = player.bank,
            crypto = player.crypto or 0,
            black_money = player.black_money or 0
        },
        job = {
            name = player.job.name,
            label = player.job.label,
            payment = player.job.salary,
            onduty = player.job.onduty ~= false,
            isboss = player.job.isBoss,
            grade = {
                level = player.job.grade,
                name = player.job.grade_label
            }
        },
        gang = {
            name = player.gang and player.gang.name or 'none',
            label = player.gang and player.gang.label or 'Ninguna',
            isboss = player.gang and player.gang.isBoss or false,
            grade = {
                level = player.gang and player.gang.grade or 0,
                name = player.gang and player.gang.grade_label or 'none'
            }
        },
        metadata = {
            hunger = player.needs.hunger,
            thirst = player.needs.thirst,
            isdead = meta.isdead == true,
            inlaststand = meta.inlaststand == true,
            injail = meta.injail or 0,
            armor = meta.armor or 0,
            stress = meta.stress or 0,
            handcuffed = meta.handcuffed == true,
            callsign = meta.callsign or 'NO-CALLSIGN'
        },
        items = player:getInventory() or {}
    }

    self.Functions = {}

    function self.Functions.GetMoney(account)
        return player:getMoney(account)
    end

    function self.Functions.AddMoney(account, amount, reason)
        local ok = player:addMoney(account, amount, reason)
        if ok then
            self.PlayerData.money[account] = player:getMoney(account)
        end
        return ok
    end

    function self.Functions.RemoveMoney(account, amount, reason)
        local ok = player:removeMoney(account, amount, reason)
        if ok then
            self.PlayerData.money[account] = player:getMoney(account)
        end
        return ok
    end

    function self.Functions.SetMoney(account, amount, reason)
        local ok = player:setMoney(account, amount, reason)
        if ok then
            self.PlayerData.money[account] = player:getMoney(account)
        end
        return ok
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
        local ok = player:setJob(jobName, grade)
        if ok then
            self.PlayerData.job = {
                name = player.job.name,
                label = player.job.label,
                payment = player.job.salary,
                onduty = player.job.onduty ~= false,
                isboss = player.job.isBoss,
                grade = { level = player.job.grade, name = player.job.grade_label }
            }
        end
        return ok
    end

    function self.Functions.SetJobDuty(onDuty)
        local state = player:setDuty(onDuty)
        self.PlayerData.job.onduty = state
        return state
    end

    function self.Functions.SetGang(gangName, grade)
        local ok = player:setGang(gangName, grade)
        if ok then
            self.PlayerData.gang = {
                name = player.gang.name,
                label = player.gang.label,
                isboss = player.gang.isBoss,
                grade = { level = player.gang.grade, name = player.gang.grade_label }
            }
        end
        return ok
    end

    function self.Functions.SetMetaData(key, val)
        self.PlayerData.metadata[key] = val
        if key == 'hunger' then
            player:setNeed('hunger', val)
        elseif key == 'thirst' then
            player:setNeed('thirst', val)
        else
            player:setMetadata(key, val)
        end
        return true
    end

    function self.Functions.GetMetaData(key)
        if key == nil then return self.PlayerData.metadata end
        if key == 'hunger' or key == 'thirst' then return player:getNeed(key) end
        return player:getMetadata(key)
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

function QBCore.Functions.CreateUseableItem(item, cb)
    if Core and Core.CreateUsableItem then
        Core.CreateUsableItem(item, cb)
    end
end

-- Handlers de evento clásicos
AddEventHandler('QBCore:GetObject', function(cb)
    cb(QBCore)
end)

-- Exports compatibles con QBCore
exports('GetCoreObject', function() return QBCore end)
exports('GetSharedObject', function() return QBCore end)
exports('GetQBCore', function() return QBCore end)
