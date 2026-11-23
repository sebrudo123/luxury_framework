-- luxury_core: Comandos y Funciones Administrativas (Servidor)

local function adminNotify(src, msg)
    if src == 0 then
        print(('[luxury_core:admin] %s'):format(msg))
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^1[Administración]^7', msg } })
    end
end

local function checkAdmin(src, minGroup)
    if src == 0 then return true end
    local player = Core.Players[src]
    return player and player:hasGroup(minGroup or 'admin')
end

--- /setGroup [id] [grupo: user|mod|admin]
local function handleSetGroup(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local targetGroup = args[2]

    if not targetId or not targetGroup or not Config.Groups[targetGroup] then
        return adminNotify(src, 'Uso: ^3/setGroup [id] [user|mod|admin]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    target.group = targetGroup
    target:sync()

    -- Persistir grupo en base de datos
    MySQL.update('UPDATE luxury_players SET `group` = ? WHERE license = ?', { targetGroup, target.license })

    adminNotify(src, ('^2Grupo de %s actualizado a: ^3%s^7'):format(target.name, targetGroup))
    adminNotify(targetId, ('^2Tu rango administrativo ha sido actualizado a: ^3%s^7'):format(targetGroup))
end
RegisterCommand('setGroup', handleSetGroup, false)
RegisterCommand('setgroup', handleSetGroup, false)

--- /setjob [id] [trabajo] [grado opcional]
local function handleSetJob(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0

    if not targetId or not jobName then
        return adminNotify(src, 'Uso: ^3/setjob [id] [trabajo] [grado opcional]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:setJob(jobName, grade) then
        adminNotify(src, ('^2Trabajo de %s asignado a: ^3%s^2 (Grado: ^3%d^2 - %s)^7'):format(
            target.name, target.job.label, target.job.grade, target.job.grade_label
        ))
        adminNotify(targetId, ('^2Tu trabajo ha sido actualizado a: ^3%s^2 (^3%s^2)^7'):format(
            target.job.label, target.job.grade_label
        ))
    else
        adminNotify(src, ('^1No se pudo asignar el trabajo "%s".^7'):format(jobName))
    end
end
RegisterCommand('setjob', handleSetJob, false)
RegisterCommand('setJob', handleSetJob, false)

--- /setgang [id] [banda] [rango opcional]
local function handleSetGang(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local gangName = args[2]
    local grade = tonumber(args[3]) or 0

    if not targetId or not gangName then
        return adminNotify(src, 'Uso: ^3/setgang [id] [banda] [rango opcional]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:setGang(gangName, grade) then
        adminNotify(src, ('^2Banda de %s asignada a: ^3%s^2 (Rango: ^3%d^2 - %s)^7'):format(
            target.name, target.gang.label, target.gang.grade, target.gang.grade_label
        ))
        adminNotify(targetId, ('^2Tu afiliación a banda ha cambiado a: ^3%s^2 (^3%s^2)^7'):format(
            target.gang.label, target.gang.grade_label
        ))
    else
        adminNotify(src, ('^1No se pudo asignar la banda "%s".^7'):format(gangName))
    end
end
RegisterCommand('setgang', handleSetGang, false)
RegisterCommand('setGang', handleSetGang, false)

--- /givemoney [id] [cash|bank|crypto] [cantidad]
local function handleGiveMoney(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local account = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not targetId or not amount or amount <= 0 then
        return adminNotify(src, 'Uso: ^3/givemoney [id] [cash|bank|crypto] [cantidad]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:addMoney(account, amount) then
        adminNotify(src, ('^2Se han añadido ^3$%s^2 a la cuenta ^3%s^2 de %s.^7'):format(amount, account, target.name))
        adminNotify(targetId, ('^2Has recibido ^3$%s^2 en tu cuenta de ^3%s^2 por la administración.^7'):format(amount, account))
    else
        adminNotify(src, '^1Error al añadir dinero a la cuenta.^7')
    end
end
RegisterCommand('givemoney', handleGiveMoney, false)
RegisterCommand('giveMoney', handleGiveMoney, false)
RegisterCommand('addmoney', handleGiveMoney, false)

--- /setmoney [id] [cash|bank|crypto] [cantidad]
local function handleSetMoney(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local account = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not targetId or amount == nil or amount < 0 then
        return adminNotify(src, 'Uso: ^3/setmoney [id] [cash|bank|crypto] [cantidad]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:setMoney(account, amount) then
        adminNotify(src, ('^2Saldo de ^3%s^2 de %s fijado en: ^3$%s^7'):format(account, target.name, amount))
        adminNotify(targetId, ('^2Tu saldo de ^3%s^2 ha sido fijado en: ^3$%s^7'):format(account, amount))
    else
        adminNotify(src, '^1Error al fijar dinero.^7')
    end
end
RegisterCommand('setmoney', handleSetMoney, false)
RegisterCommand('setMoney', handleSetMoney, false)

--- /giveitem [id] [item] [cantidad opcional]
local function handleGiveItem(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local itemName = args[2]
    local count = tonumber(args[3]) or 1

    if not targetId or not itemName then
        return adminNotify(src, 'Uso: ^3/giveitem [id] [item] [cantidad opcional]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    local ok, err = target:addItem(itemName, count)
    if ok then
        adminNotify(src, ('^2Entregado ^3%s x%d^2 a %s.^7'):format(itemName, count, target.name))
        adminNotify(targetId, ('^2Has recibido ^3%s x%d^2 en tu inventario.^7'):format(itemName, count))
    else
        adminNotify(src, ('^1No se pudo entregar el ítem: %s^7'):format(err or 'ox_inventory no disponible'))
    end
end
RegisterCommand('giveitem', handleGiveItem, false)
RegisterCommand('giveItem', handleGiveItem, false)

--- /clearinventory [id opcional]
local function handleClearInventory(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1]) or (src ~= 0 and src or nil)
    if not targetId then
        return adminNotify(src, 'Uso: ^3/clearinventory [id]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:clearInventory() then
        adminNotify(src, ('^2Inventario de %s limpiado con éxito.^7'):format(target.name))
        adminNotify(targetId, '^3Tu inventario ha sido vaciado por la administración.^7')
    else
        adminNotify(src, '^1No se pudo limpiar el inventario (ox_inventory no está listo).^7')
    end
end
RegisterCommand('clearinventory', handleClearInventory, false)
RegisterCommand('clearInventory', handleClearInventory, false)

--- /heal [id opcional]
RegisterCommand('heal', function(src, args)
    if not checkAdmin(src, 'mod') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1]) or src
    if targetId == 0 then
        return adminNotify(src, 'Debes especificar una ID válida desde la consola.')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    target:setNeed('hunger', 100)
    target:setNeed('thirst', 100)
    TriggerClientEvent('luxury:admin:clientHeal', targetId)
    adminNotify(src, ('^2Jugador %s curado al máximo.^7'):format(target.name))
end, false)

--- /goto [id] (teletransportarse hacia un jugador)
RegisterCommand('goto', function(src, args)
    if not checkAdmin(src, 'mod') or src == 0 then
        return adminNotify(src, '^1No tienes permisos suficientes o debes ejecutarlo en el juego.^7')
    end

    local targetId = tonumber(args[1])
    if not targetId or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/goto [id]^7')
    end

    local target = Core.Players[targetId]
    local targetPed = GetPlayerPed(targetId)
    if targetPed and DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        TriggerClientEvent('luxury:admin:teleport', src, coords)
        adminNotify(src, ('Te has teletransportado hacia ^3%s^7.'):format(target.name))
    end
end, false)

--- /revive [id opcional]
RegisterCommand('revive', function(src, args)
    if not checkAdmin(src, 'mod') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1]) or src
    if targetId == 0 then
        return adminNotify(src, 'Debes especificar una ID válida desde la consola.')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    TriggerClientEvent('luxury:admin:clientRevive', targetId)
    TriggerClientEvent('luxury:client:revivePlayer', targetId)
    adminNotify(src, ('^2Jugador %s (ID: %d) revivido con éxito.^7'):format(target.name, targetId))
end, false)

--- /tp [id | x y z]
RegisterCommand('tp', function(src, args)
    if not checkAdmin(src, 'mod') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    if src == 0 then
        return adminNotify(src, 'Este comando solo puede ejecutarse desde el juego.')
    end

    -- Teletransporte a coordenadas: /tp x y z
    if args[1] and args[2] and args[3] then
        local x = tonumber(args[1])
        local y = tonumber(args[2])
        local z = tonumber(args[3])
        if x and y and z then
            TriggerClientEvent('luxury:admin:teleport', src, vector3(x, y, z))
            return adminNotify(src, ('Teletransportado a ^3%.2f, %.2f, %.2f^7'):format(x, y, z))
        end
    end

    -- Teletransporte a jugador: /tp [id]
    local targetId = tonumber(args[1])
    if targetId then
        local target = Core.Players[targetId]
        if not target then return adminNotify(src, '^1Jugador no encontrado.^7') end

        local targetPed = GetPlayerPed(targetId)
        if targetPed and DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            TriggerClientEvent('luxury:admin:teleport', src, coords)
            adminNotify(src, ('Teletransportado hacia ^3%s^7'):format(target.name))
        end
        return
    end

    adminNotify(src, 'Uso: ^3/tp [id]^7 o ^3/tp [x] [y] [z]^7')
end, false)

--- /bring [id] (trae a un jugador hacia el admin)
RegisterCommand('bring', function(src, args)
    if not checkAdmin(src, 'mod') or src == 0 then
        return adminNotify(src, '^1No tienes permisos suficientes.^7')
    end

    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    local adminPed = GetPlayerPed(src)
    local coords = GetEntityCoords(adminPed)

    TriggerClientEvent('luxury:admin:teleport', targetId, coords)
    adminNotify(src, ('Has traído a ^3%s^7 hacia tu posición.'):format(target.name))
    adminNotify(targetId, '^3Has sido teletransportado por un administrador.^7')
end, false)

--- /freeze [id] (congela o descongela a un jugador)
RegisterCommand('freeze', function(src, args)
    if not checkAdmin(src, 'mod') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    target.isFrozen = not target.isFrozen
    TriggerClientEvent('luxury:admin:freeze', targetId, target.isFrozen)
    adminNotify(src, ('Jugador %s ^3%s^7.'):format(target.name, target.isFrozen and 'CONGELADO' or 'DESCONGELADO'))
end, false)

--- /kick [id] [motivo]
RegisterCommand('kick', function(src, args)
    if not checkAdmin(src, 'mod') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    if not targetId or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/kick [id] [motivo]^7')
    end

    table.remove(args, 1)
    local reason = #args > 0 and table.concat(args, ' ') or 'Expulsado por la administración'

    local adminName = src == 0 and 'Consola' or GetPlayerName(src)
    DropPlayer(targetId, ('Has sido expulsado por %s. Motivo: %s'):format(adminName, reason))
    adminNotify(src, ('Jugador ID %d expulsado. Motivo: %s'):format(targetId, reason))
end, false)

--- /anuncio [mensaje]
RegisterCommand('anuncio', function(src, args)
    if not checkAdmin(src, 'mod') then
        return adminNotify(src, '^1No tienes permisos suficientes.^7')
    end

    if #args == 0 then
        return adminNotify(src, 'Uso: ^3/anuncio [mensaje]^7')
    end

    local msg = table.concat(args, ' ')
    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^1[ANUNCIO COMUNITARIO]^7', msg }
    })
end, false)

--- /ban [id] [horas (0=permanente)] [motivo]
RegisterCommand('ban', function(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local targetId = tonumber(args[1])
    local durationHours = tonumber(args[2])

    if not targetId or durationHours == nil or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/ban [id] [horas: 0=permanente] [motivo]^7')
    end

    local target = Core.Players[targetId]
    table.remove(args, 1)
    table.remove(args, 1)
    local reason = #args > 0 and table.concat(args, ' ') or 'Sanción administrativa'

    local adminName = src == 0 and 'Consola' or GetPlayerName(src)
    Security.BanPlayer(targetId, ('%s (Por %s)'):format(reason, adminName), durationHours)
    adminNotify(src, ('^2Jugador %s sancionado con HWID Ban exitosamente.^7'):format(target.name))
end, false)

--- /unban [license]
RegisterCommand('unban', function(src, args)
    if not checkAdmin(src, 'admin') then
        return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
    end

    local license = args[1]
    if not license then
        return adminNotify(src, 'Uso: ^3/unban [license:xxxxx]^7')
    end

    local affected = MySQL.update.await('DELETE FROM luxury_bans WHERE license = ? OR ip = ? OR identifiers LIKE ?', { license, license, '%' .. license .. '%' })
    if affected and affected > 0 then
        adminNotify(src, ('^2La licencia %s ha sido desbaneada.^7'):format(license))
        MySQL.insert('INSERT INTO luxury_logs (type, identifier, action) VALUES (?, ?, ?)', {
            'unban', license, ('Desbaneado por %s'):format(src == 0 and 'Consola' or GetPlayerName(src))
        })
    else
        adminNotify(src, '^1No se encontró ningún baneo activo para esa licencia.^7')
    end
end, false)
