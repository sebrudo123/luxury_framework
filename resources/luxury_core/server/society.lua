-- luxury_core: Sistema de Facciones, Fondos y Gestión de Jefes (Society / Boss)
Society = {}

--- Obtiene el dinero de una sociedad
-- @param name string: Nombre de la facción (ej: 'police', 'ambulance')
-- @return number
function Society.GetMoney(name)
    local row = MySQL.single.await('SELECT money FROM luxury_societies WHERE name = ?', { name })
    return row and row.money or 0
end

--- Ingresa dinero en la cuenta de una sociedad
-- @param name string
-- @param amount number
-- @return boolean
function Society.AddMoney(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local affected = MySQL.update.await('UPDATE luxury_societies SET money = money + ? WHERE name = ?', { amount, name })
    return affected and affected > 0
end

--- Retira dinero de la cuenta de una sociedad si hay fondos suficientes
-- @param name string
-- @param amount number
-- @return boolean
function Society.RemoveMoney(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local current = Society.GetMoney(name)
    if current < amount then return false end

    local affected = MySQL.update.await('UPDATE luxury_societies SET money = money - ? WHERE name = ?', { amount, name })
    return affected and affected > 0
end

-- Exports
exports('GetSocietyMoney', Society.GetMoney)
exports('AddSocietyMoney', Society.AddMoney)
exports('RemoveSocietyMoney', Society.RemoveMoney)

---------------------------------------------------------------------
-- Puente nativo esx_addonaccount (Compatible con okokBanking / luxury_banking / esx_society)
---------------------------------------------------------------------
AddEventHandler('esx_addonaccount:getSharedAccount', function(accountName, cb)
    if type(cb) ~= 'function' or type(accountName) ~= 'string' then return end
    local socName = accountName:gsub('^society_', '')
    local currentMoney = Society.GetMoney(socName)

    local accountObj = {
        name = accountName,
        money = currentMoney,
        addMoney = function(amount)
            local ok = Society.AddMoney(socName, amount)
            if ok and Logger and Logger.LogEconomy then
                Logger.LogEconomy(0, accountName, amount, 'Depósito Sociedad', 'Via esx_addonaccount bridge')
            end
            return ok
        end,
        removeMoney = function(amount)
            local ok = Society.RemoveMoney(socName, amount)
            if ok and Logger and Logger.LogEconomy then
                Logger.LogEconomy(0, accountName, amount, 'Retiro Sociedad', 'Via esx_addonaccount bridge')
            end
            return ok
        end,
        setMoney = function(amount)
            amount = math.max(0, math.floor(tonumber(amount) or 0))
            local affected = MySQL.update.await('UPDATE luxury_societies SET money = ? WHERE name = ?', { amount, socName })
            return affected and affected > 0
        end
    }
    cb(accountObj)
end)

---------------------------------------------------------------------
-- Comandos de Gestión para Jefes (Boss Menu Commands)
---------------------------------------------------------------------
local function notify(src, msg)
    TriggerClientEvent('chat:addMessage', src, { args = { '^3[Sociedad]^7', msg } })
end

local function isBoss(src)
    local player = Core.Players[src]
    if not player then return false end
    local jobInfo = GetJobInfo(player.job.name, player.job.grade)
    return jobInfo and jobInfo.isBoss
end

--- /sociedad [consultar | ingresar | retirar] [cantidad]
RegisterCommand('sociedad', function(src, args)
    if src == 0 then return print('Comando exclusivo para jugadores.') end
    local player = Core.Players[src]
    if not player or not isBoss(src) then
        return notify(src, '^1No eres el jefe de tu facción/empresa.^7')
    end

    local action = args[1]
    local societyName = player.job.name

    if action == 'consultar' or not action then
        local balance = Society.GetMoney(societyName)
        return notify(src, ('Fondos de ^3%s^7: ^2$%d^7'):format(player.job.label, balance))
    elseif action == 'ingresar' then
        local amount = tonumber(args[2])
        if not amount or amount <= 0 then return notify(src, 'Uso: ^3/sociedad ingresar [cantidad]^7') end

        if player:removeMoney('cash', amount) then
            Society.AddMoney(societyName, amount)
            notify(src, ('Has ingresado ^2$%d^7 a los fondos de la empresa.'):format(amount))
        else
            notify(src, '^1No tienes suficiente dinero en efectivo para ingresar.^7')
        end
    elseif action == 'retirar' then
        local amount = tonumber(args[2])
        if not amount or amount <= 0 then return notify(src, 'Uso: ^3/sociedad retirar [cantidad]^7') end

        if Society.RemoveMoney(societyName, amount) then
            player:addMoney('cash', amount)
            notify(src, ('Has retirado ^2$%d^7 de los fondos de la empresa.'):format(amount))
        else
            notify(src, '^1La cuenta de la empresa no dispone de fondos suficientes.^7')
        end
    else
        notify(src, 'Uso: ^3/sociedad [consultar|ingresar|retirar] [cantidad]^7')
    end
end, false)

--- /contratar [id]: Contrata a un jugador cercano en el rango 0 de la empresa
RegisterCommand('contratar', function(src, args)
    if src == 0 then return end
    local boss = Core.Players[src]
    if not boss or not isBoss(src) then
        return notify(src, '^1No eres el jefe de tu facción.^7')
    end

    local targetId = tonumber(args[1])
    if not targetId then return notify(src, 'Uso: ^3/contratar [id]^7') end

    local target = Core.Players[targetId]
    if not target then return notify(src, '^1El jugador no está conectado.^7') end

    if target.job.name ~= 'unemployed' then
        return notify(src, '^1El jugador ya tiene un trabajo. Debe renunciar primero.^7')
    end

    target:setJob(boss.job.name, 0)
    notify(src, ('Has contratado a ^2%s^7 en ^3%s^7.'):format(target.name, boss.job.label))
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '^2[Empleo]^7', ('¡Has sido contratado en ^3%s^7 como ^2%s^7!'):format(boss.job.label, target.job.grade_label) }
    })
end, false)

--- /despedir [id]: Despide a un empleado dejándolo desempleado
RegisterCommand('despedir', function(src, args)
    if src == 0 then return end
    local boss = Core.Players[src]
    if not boss or not isBoss(src) then
        return notify(src, '^1No eres el jefe de tu facción.^7')
    end

    local targetId = tonumber(args[1])
    if not targetId then return notify(src, 'Uso: ^3/despedir [id]^7') end

    local target = Core.Players[targetId]
    if not target then return notify(src, '^1El jugador no está conectado.^7') end

    if target.job.name ~= boss.job.name then
        return notify(src, '^1Este jugador no trabaja en tu empresa.^7')
    end

    target:setJob('unemployed', 0)
    notify(src, ('Has despedido a ^3%s^7.'):format(target.name))
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '^1[Empleo]^7', ('Has sido despedido de ^3%s^7.'):format(boss.job.label) }
    })
end, false)

--- /ascender [id]: Sube de rango a un empleado
RegisterCommand('ascender', function(src, args)
    if src == 0 then return end
    local boss = Core.Players[src]
    if not boss or not isBoss(src) then return notify(src, '^1Sin permisos de jefe.^7') end

    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target or target.job.name ~= boss.job.name then
        return notify(src, '^1Jugador no válido o no pertenece a tu empresa.^7')
    end

    local nextGrade = target.job.grade + 1
    local jobData = Jobs[boss.job.name]
    if not jobData or not jobData.grades[nextGrade] then
        return notify(src, '^1El empleado ya ha alcanzado el rango máximo disponible.^7')
    end

    target:setJob(boss.job.name, nextGrade)
    notify(src, ('Has ascendido a ^2%s^7 a ^3%s^7.'):format(target.name, target.job.grade_label))
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '^2[Ascenso]^7', ('¡Has sido ascendido a ^3%s^7!'):format(target.job.grade_label) }
    })
end, false)

--- /degradar [id]: Baja de rango a un empleado
RegisterCommand('degradar', function(src, args)
    if src == 0 then return end
    local boss = Core.Players[src]
    if not boss or not isBoss(src) then return notify(src, '^1Sin permisos de jefe.^7') end

    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target or target.job.name ~= boss.job.name then
        return notify(src, '^1Jugador no válido o no pertenece a tu empresa.^7')
    end

    local prevGrade = target.job.grade - 1
    if prevGrade < 0 then
        return notify(src, '^1El empleado ya está en el rango más bajo. Puedes despedirlo con /despedir.^7')
    end

    target:setJob(boss.job.name, prevGrade)
    notify(src, ('Has degradado a ^3%s^7 a ^3%s^7.'):format(target.name, target.job.grade_label))
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '^1[Degradado]^7', ('Has sido degradado a ^3%s^7.'):format(target.job.grade_label) }
    })
end, false)
