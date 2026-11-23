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
        grade_salary = player.job.salary
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
        return {
            name = account,
            money = player:getMoney(accName),
            round = true,
            label = accName == 'cash' and 'Efectivo' or 'Banco'
        }
    end

    function self.getAccounts()
        return {
            self.getAccount('cash'),
            self.getAccount('bank')
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
                grade_salary = updatedJob.salary
            }
        end
        return success
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

-- Handlers de evento clásicos para scripts ESX antiguos
AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

-- Exports compatibles con ESX
exports('getSharedObject', function() return ESX end)
exports('GetSharedObject', function() return ESX end)
exports('GetESX', function() return ESX end)
