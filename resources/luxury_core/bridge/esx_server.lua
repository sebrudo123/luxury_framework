-- luxury_core: Puente de Compatibilidad con ESX (Legacy y v1 Final)
ESX = ESX or {}
ESX.Players = {}
ESX.ServerCallbacks = {}

---------------------------------------------------------------------
-- Wrapper / Adaptador xPlayer de ESX
---------------------------------------------------------------------
local function buildXPlayer(player)
    local self = {}
    self.source = player.source
    self.identifier = player.license
    self.name = player.name
    self.group = player.group

    local jobData = Jobs[player.job.name]
    local gradeData = jobData and jobData.grades[player.job.grade] or {}

    self.job = {
        name = player.job.name,
        label = player.job.label,
        grade = player.job.grade,
        grade_name = gradeData.name or 'default',
        grade_label = player.job.grade_label,
        grade_salary = player.job.salary,
        onduty = player.job.onduty ~= false
    }

    self.coords = player:getCoords()

    -- Métodos de Dinero y Cuentas
    function self.getMoney()
        return player:getMoney('cash')
    end

    function self.addMoney(amount)
        return player:addMoney('cash', amount)
    end

    function self.removeMoney(amount)
        return player:removeMoney('cash', amount)
    end

    function self.setMoney(amount)
        return player:setMoney('cash', amount)
    end

    function self.getAccount(account)
        local accName = account == 'money' and 'cash' or account
        local labels = { cash = 'Efectivo', bank = 'Banco', black_money = 'Dinero Negro', crypto = 'Cripto' }
        return {
            name = account,
            money = player:getMoney(accName),
            round = true,
            label = labels[accName] or account
        }
    end

    function self.getAccounts()
        return {
            self.getAccount('cash'),
            self.getAccount('bank'),
            self.getAccount('black_money')
        }
    end

    function self.addAccountMoney(account, amount)
        local accName = account == 'money' and 'cash' or account
        return player:addMoney(accName, amount)
    end

    function self.removeAccountMoney(account, amount)
        local accName = account == 'money' and 'cash' or account
        return player:removeMoney(accName, amount)
    end

    function self.setAccountMoney(account, amount)
        local accName = account == 'money' and 'cash' or account
        return player:setMoney(accName, amount)
    end

    -- Métodos de Trabajo
    function self.getJob()
        return self.job
    end

    function self.setJob(jobName, grade)
        local success = player:setJob(jobName, grade)
        if success then
            local updatedJob = player.job
            local gData = (Jobs[jobName] and Jobs[jobName].grades[tonumber(grade) or 0]) or {}
            self.job = {
                name = updatedJob.name,
                label = updatedJob.label,
                grade = updatedJob.grade,
                grade_name = gData.name or 'default',
                grade_label = updatedJob.grade_label,
                grade_salary = updatedJob.salary,
                onduty = updatedJob.onduty ~= false
            }
        end
        return success
    end

    function self.setDuty(state)
        local newState = player:setDuty(state)
        self.job.onduty = newState
        return newState
    end

    function self.getDuty()
        return player:isOnDuty()
    end

    -- Métodos de Inventario (Delegados al puente ox_inventory)
    function self.getInventory(minimal)
        local raw = player:getInventory() or {}
        if minimal then
            local min = {}
            for _, item in pairs(raw) do
                if item and item.name and (item.count or 0) > 0 then
                    min[item.name] = item.count
                end
            end
            return min
        end
        return raw
    end

    function self.getInventoryItem(name)
        local item = player:getItem(name)
        if not item then
            return { name = name, count = 0, label = name, weight = 0, usable = false, rare = false, canRemove = false }
        end
        return {
            name = item.name,
            count = item.count or item.amount or 0,
            label = item.label or item.name,
            weight = item.weight or 0,
            usable = true,
            rare = false,
            canRemove = true
        }
    end

    function self.addInventoryItem(name, count, metadata)
        return player:addItem(name, count, metadata)
    end

    function self.removeInventoryItem(name, count, metadata)
        return player:removeItem(name, count, metadata)
    end

    function self.hasItem(name)
        return player:hasItem(name, 1)
    end

    function self.canCarryItem(name, count)
        return player:canCarryItem(name, count or 1)
    end

    function self.getWeight()
        local weight = 0
        local inv = player:getInventory() or {}
        for _, item in pairs(inv) do
            if item and item.weight and item.count then
                weight = weight + (item.weight * item.count)
            end
        end
        return weight
    end

    function self.getMaxWeight()
        return 30000 -- 30kg estándar de inventario
    end

    function self.setInventoryItem(name, count)
        local cur = player:getItem(name)
        local curCount = cur and (cur.count or cur.amount or 0) or 0
        local diff = (count or 0) - curCount
        if diff > 0 then
            return player:addItem(name, diff)
        elseif diff < 0 then
            return player:removeItem(name, math.abs(diff))
        end
        return true
    end

    -- Métodos de Identidad y Coordenadas
    function self.getIdentifier()
        return player.license
    end

    function self.getGroup()
        return player.group
    end

    function self.setGroup(newGroup)
        player.group = newGroup
        player:sync()
    end

    function self.getCoords(isVector)
        local c = player:getCoords()
        return isVector and vector3(c.x, c.y, c.z) or c
    end

    function self.showNotification(msg, notifyType)
        TriggerClientEvent('esx:showNotification', player.source, msg, notifyType)
    end

    return self
end

---------------------------------------------------------------------
-- Funciones Globales del Servidor ESX
---------------------------------------------------------------------
function ESX.GetPlayerFromId(src)
    local player = Core.Players[tonumber(src)]
    return player and buildXPlayer(player) or nil
end

function ESX.GetPlayerFromIdentifier(identifier)
    for _, player in pairs(Core.Players) do
        if player.license == identifier then
            return buildXPlayer(player)
        end
    end
    return nil
end

function ESX.GetPlayers()
    local sources = {}
    for src, _ in pairs(Core.Players) do
        sources[#sources + 1] = src
    end
    return sources
end

function ESX.GetExtendedPlayers(key, val)
    local list = {}
    for _, player in pairs(Core.Players) do
        local xPlayer = buildXPlayer(player)
        if not key or xPlayer[key] == val or (xPlayer.job and xPlayer.job[key] == val) then
            list[#list + 1] = xPlayer
        end
    end
    return list
end

function ESX.RegisterServerCallback(name, cb)
    ESX.ServerCallbacks[name] = cb
    -- Conectar con el sistema de callbacks nativo de luxury_lib
    if Luxury and Luxury.RegisterCallback then
        Luxury.RegisterCallback(name, cb)
    end
end

RegisterNetEvent('esx:triggerServerCallback', function(name, requestId, ...)
    local src = source
    local cb = ESX.ServerCallbacks[name]
    if cb then
        cb(src, function(...)
            TriggerClientEvent('esx:serverCallback', src, requestId, ...)
        end, ...)
    else
        print(('[^1ESX BRIDGE^7] Callback no registrado: %s'):format(name))
    end
end)

function ESX.ShowNotification(src, msg, nType)
    TriggerClientEvent('esx:showNotification', src, msg, nType)
end

function ESX.RegisterUsableItem(item, cb)
    if Core and Core.CreateUsableItem then
        Core.CreateUsableItem(item, cb)
    end
end

-- Handlers de evento clásicos para scripts ESX antiguos
AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

function ESX.GetConfig()
    return {
        EnableCustomInventory = true,
        CustomInventory = 'ox',
        DistanceGive = 4.0
    }
end

function ESX.GetJobs()
    return Jobs or {}
end

function ESX.GetItems()
    return Items or {}
end

-- Exports compatibles con ESX
exports('getSharedObject', function() return ESX end)
exports('GetSharedObject', function() return ESX end)
exports('GetESX', function() return ESX end)
