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

--- Helper centralizado para registrar comandos administrativos con permisos y auditoría Discord
local function registerAdminCommands(names, minGroup, handler, allowConsole)
    local nameList = type(names) == 'table' and names or { names }
    for _, cmdName in ipairs(nameList) do
        RegisterCommand(cmdName, function(src, args)
            if src == 0 and allowConsole == false then
                return adminNotify(src, 'Este comando solo puede ejecutarse desde el juego.')
            end
            if not checkAdmin(src, minGroup) then
                return adminNotify(src, '^1No tienes permiso para usar este comando.^7')
            end
            if Logger and Logger.LogAdminCommand then
                Logger.LogAdminCommand(src, cmdName, args)
            end
            handler(src, args)
        end, false)
    end
end

---------------------------------------------------------------------
-- Gestión de Rangos, Trabajos, Bandas, Economía e Inventario
---------------------------------------------------------------------

--- /setGroup [id] [grupo: user|mod|admin]
registerAdminCommands({ 'setGroup', 'setgroup' }, 'admin', function(src, args)
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

    MySQL.update('UPDATE luxury_players SET `group` = ? WHERE citizenid = ? AND license = ?', {
        targetGroup, target.citizenid, target.license
    })

    adminNotify(src, ('^2Grupo de %s actualizado a: ^3%s^7'):format(target.name, targetGroup))
    adminNotify(targetId, ('^2Tu rango administrativo ha sido actualizado a: ^3%s^7'):format(targetGroup))
end, true)

--- /setjob [id] [trabajo] [grado opcional]
registerAdminCommands({ 'setjob', 'setJob' }, 'admin', function(src, args)
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
end, true)

--- /setgang [id] [banda] [rango opcional]
registerAdminCommands({ 'setgang', 'setGang' }, 'admin', function(src, args)
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
end, true)

--- /givemoney [id] [cash|bank|black_money|crypto] [cantidad]
registerAdminCommands({ 'givemoney', 'giveMoney', 'addmoney', 'darDinero' }, 'admin', function(src, args)
    local targetId = tonumber(args[1])
    local account = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not targetId or not amount or amount <= 0 then
        return adminNotify(src, 'Uso: ^3/givemoney [id] [cash|bank|black_money|crypto] [cantidad]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:addMoney(account, amount, 'Comando administrativo /givemoney') then
        adminNotify(src, ('^2Se han añadido ^3$%s^2 a la cuenta ^3%s^2 de %s.^7'):format(amount, account, target.name))
        adminNotify(targetId, ('^2Has recibido ^3$%s^2 en tu cuenta de ^3%s^2 por la administración.^7'):format(amount, account))
    else
        adminNotify(src, '^1Cuenta inválida o monto incorrecto (cuentas: cash, bank, black_money, crypto).^7')
    end
end, true)

--- /setmoney [id] [cash|bank|black_money|crypto] [cantidad]
registerAdminCommands({ 'setmoney', 'setMoney' }, 'admin', function(src, args)
    local targetId = tonumber(args[1])
    local account = args[2] or 'cash'
    local amount = tonumber(args[3])

    if not targetId or amount == nil or amount < 0 then
        return adminNotify(src, 'Uso: ^3/setmoney [id] [cash|bank|black_money|crypto] [cantidad]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    if target:setMoney(account, amount, 'Comando administrativo /setmoney') then
        adminNotify(src, ('^2Saldo de ^3%s^2 de %s fijado en: ^3$%s^7'):format(account, target.name, amount))
        adminNotify(targetId, ('^2Tu saldo de ^3%s^2 ha sido fijado en: ^3$%s^7'):format(account, amount))
    else
        adminNotify(src, '^1Error al fijar dinero (cuentas: cash, bank, black_money, crypto).^7')
    end
end, true)

--- /giveitem [id] [item] [cantidad opcional]
registerAdminCommands({ 'giveitem', 'giveItem' }, 'admin', function(src, args)
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
end, true)

--- /clearinventory [id opcional]
registerAdminCommands({ 'clearinventory', 'clearInventory' }, 'admin', function(src, args)
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
end, true)

---------------------------------------------------------------------
-- Moderación, Salud, Armadura, Vehículos y Teletransporte
---------------------------------------------------------------------

--- /heal [id opcional]
registerAdminCommands('heal', 'mod', function(src, args)
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
end, true)

--- /armor [id opcional] [cantidad 0-100]
registerAdminCommands('armor', 'mod', function(src, args)
    local targetId = tonumber(args[1]) or src
    local amount = tonumber(args[2]) or 100
    if targetId == 0 then
        return adminNotify(src, 'Uso desde consola: ^3/armor [id] [cantidad]^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    amount = math.max(0, math.min(100, math.floor(amount)))
    target:setMetadata('armor', amount)
    TriggerClientEvent('luxury:admin:clientArmor', targetId, amount)
    adminNotify(src, ('^2Chaleco de %s ajustado a ^3%d%%^7.'):format(target.name, amount))
end, true)

--- /revive [id opcional]
registerAdminCommands('revive', 'mod', function(src, args)
    local targetId = tonumber(args[1]) or src
    if targetId == 0 then
        return adminNotify(src, 'Debes especificar una ID válida desde la consola.')
    end

    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    target:setMetadata('isdead', false)
    target:setMetadata('inlaststand', false)
    TriggerClientEvent('luxury:admin:clientRevive', targetId)
    TriggerClientEvent('luxury:client:revivePlayer', targetId)
    adminNotify(src, ('^2Jugador %s (ID: %d) revivido con éxito.^7'):format(target.name, targetId))
end, true)

--- /slay [id opcional] o /kill [id opcional]
registerAdminCommands({ 'slay', 'kill' }, 'admin', function(src, args)
    local targetId = tonumber(args[1]) or src
    if targetId == 0 or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/slay [id]^7')
    end
    TriggerClientEvent('luxury:admin:clientSlay', targetId)
    adminNotify(src, ('^3Jugador %s (ID: %d) abatido por administración.^7'):format(Core.Players[targetId].name, targetId))
end, true)

--- /cleararea [radio opcional]: Limpia vehículos vacíos, props y peds en el área
registerAdminCommands('cleararea', 'mod', function(src, args)
    local radius = math.max(5, math.min(200, math.floor(tonumber(args[1]) or 40)))
    TriggerClientEvent('luxury:admin:clientClearArea', src, radius)
    adminNotify(src, ('Limpieza de área ejecutada en un radio de ^3%dm^7.'):format(radius))
end, false)

--- /goto [id]
registerAdminCommands('goto', 'mod', function(src, args)
    local targetId = tonumber(args[1])
    if not targetId or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/goto [id]^7')
    end

    local target = Core.Players[targetId]
    local targetPed = GetPlayerPed(targetId)
    if targetPed and DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        if Security and Security.MarkTeleport then Security.MarkTeleport(src) end
        TriggerClientEvent('luxury:admin:teleport', src, coords)
        adminNotify(src, ('Te has teletransportado hacia ^3%s^7.'):format(target.name))
    end
end, false)

--- /tp [id | x y z]
registerAdminCommands('tp', 'mod', function(src, args)
    if args[1] and args[2] and args[3] then
        local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if x and y and z then
            if Security and Security.MarkTeleport then Security.MarkTeleport(src) end
            TriggerClientEvent('luxury:admin:teleport', src, vector3(x, y, z))
            return adminNotify(src, ('Teletransportado a ^3%.2f, %.2f, %.2f^7'):format(x, y, z))
        end
    end

    local targetId = tonumber(args[1])
    if targetId then
        local target = Core.Players[targetId]
        if not target then return adminNotify(src, '^1Jugador no encontrado.^7') end

        local targetPed = GetPlayerPed(targetId)
        if targetPed and DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            if Security and Security.MarkTeleport then Security.MarkTeleport(src) end
            TriggerClientEvent('luxury:admin:teleport', src, coords)
            adminNotify(src, ('Teletransportado hacia ^3%s^7'):format(target.name))
        end
        return
    end

    adminNotify(src, 'Uso: ^3/tp [id]^7 o ^3/tp [x] [y] [z]^7')
end, false)

--- /bring [id]
registerAdminCommands('bring', 'mod', function(src, args)
    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    local adminPed = GetPlayerPed(src)
    local coords = GetEntityCoords(adminPed)

    if Security and Security.MarkTeleport then
        Security.MarkTeleport(targetId)
    end
    TriggerClientEvent('luxury:admin:teleport', targetId, coords)
    adminNotify(src, ('Has traído a ^3%s^7 hacia tu posición.'):format(target.name))
    adminNotify(targetId, '^3Has sido teletransportado por un administrador.^7')
end, false)

--- /spec [id] o /spectate [id]: Espectear jugador sin ID para salir
registerAdminCommands({ 'spec', 'spectate' }, 'mod', function(src, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('luxury:admin:clientSpectate', src, nil, nil)
        return
    end

    if targetId == src or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/spec [id válida]^7 (o ^3/spec^7 sin ID para salir).')
    end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed or not DoesEntityExist(targetPed) then
        return adminNotify(src, '^1No se pudo localizar el ped del jugador.^7')
    end

    local targetCoords = GetEntityCoords(targetPed)
    TriggerClientEvent('luxury:admin:clientSpectate', src, targetId, targetCoords)
    adminNotify(src, ('Observando a ^3%s (ID: %d)^7. Usa ^3/spec^7 para volver.'):format(Core.Players[targetId].name, targetId))
end, false)

--- /setplate [placa]: Cambia la matrícula del vehículo actual en mundo y BD
registerAdminCommands('setplate', 'admin', function(src, args)
    local rawPlate = args[1]
    if not rawPlate then
        return adminNotify(src, 'Uso: ^3/setplate [MATRICULA]^7 (máximo 8 caracteres)')
    end

    local newPlate = rawPlate:upper():gsub('[^A-Z0-9]', ''):sub(1, 8)
    if #newPlate < 1 then
        return adminNotify(src, '^1Matrícula inválida.^7')
    end

    TriggerClientEvent('luxury:admin:clientSetPlate', src, newPlate)
end, false)

RegisterNetEvent('luxury:admin:updateVehiclePlateDB', function(oldPlate, newPlate)
    local src = source
    if not checkAdmin(src, 'admin') or not oldPlate or not newPlate then return end
    oldPlate = tostring(oldPlate):gsub('^%s+', ''):gsub('%s+$', '')

    pcall(function()
        MySQL.update('UPDATE player_vehicles SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
        MySQL.update('UPDATE owned_vehicles SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
    end)
    adminNotify(src, ('^2Matrícula actualizada de ^3%s^2 a ^3%s^7.'):format(oldPlate, newPlate))
end)

--- /freeze [id]
registerAdminCommands('freeze', 'mod', function(src, args)
    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target then
        return adminNotify(src, '^1Jugador no encontrado.^7')
    end

    target.isFrozen = not target.isFrozen
    TriggerClientEvent('luxury:admin:freeze', targetId, target.isFrozen)
    adminNotify(src, ('Jugador %s ^3%s^7.'):format(target.name, target.isFrozen and 'CONGELADO' or 'DESCONGELADO'))
end, true)

--- /admins y /players
registerAdminCommands('admins', 'mod', function(src)
    local staff = {}
    for id, player in pairs(Core.Players) do
        if player:hasGroup('mod') then
            staff[#staff + 1] = ('%s (ID: %d | %s)'):format(player.name, id, player.group)
        end
    end
    adminNotify(src, ('Staff en línea (%d): ^3%s^7'):format(#staff, #staff > 0 and table.concat(staff, ', ') or 'Ninguno'))
end, true)

registerAdminCommands('players', 'mod', function(src)
    local list = {}
    for id, player in pairs(Core.Players) do
        list[#list + 1] = ('[%d] %s (%s)'):format(id, player.name, player.job.name)
    end
    adminNotify(src, ('Jugadores conectados (%d): ^3%s^7'):format(#list, #list > 0 and table.concat(list, ' | ') or 'Ninguno'))
end, true)

--- /reply [id] [mensaje] (responder a reportes)
registerAdminCommands({ 'reply', 're' }, 'mod', function(src, args)
    local targetId = tonumber(args[1])
    if not targetId or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/reply [id] [respuesta]^7')
    end
    table.remove(args, 1)
    if #args == 0 then
        return adminNotify(src, 'Uso: ^3/reply [id] [respuesta]^7')
    end
    local msg = table.concat(args, ' ')
    local staffName = src == 0 and 'Consola' or (Core.Players[src] and Core.Players[src].name or GetPlayerName(src))

    TriggerClientEvent('chat:addMessage', targetId, {
        args = { ('^2[Respuesta Staff | %s]^7'):format(staffName), msg }
    })
    adminNotify(src, ('Respuesta enviada a ^3%s (ID: %d)^7: %s'):format(Core.Players[targetId].name, targetId, msg))
end, true)

--- /kick [id] [motivo]
registerAdminCommands('kick', 'mod', function(src, args)
    local targetId = tonumber(args[1])
    if not targetId or not Core.Players[targetId] then
        return adminNotify(src, 'Uso: ^3/kick [id] [motivo]^7')
    end

    table.remove(args, 1)
    local reason = #args > 0 and table.concat(args, ' ') or 'Expulsado por la administración'

    local adminName = src == 0 and 'Consola' or GetPlayerName(src)
    DropPlayer(targetId, ('Has sido expulsado por %s. Motivo: %s'):format(adminName, reason))
    adminNotify(src, ('Jugador ID %d expulsado. Motivo: %s'):format(targetId, reason))
end, true)

--- /anuncio [mensaje]
registerAdminCommands('anuncio', 'mod', function(src, args)
    if #args == 0 then
        return adminNotify(src, 'Uso: ^3/anuncio [mensaje]^7')
    end

    local msg = table.concat(args, ' ')
    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^1[ANUNCIO COMUNITARIO]^7', msg }
    })
end, true)

--- /ban [id] [horas (0=permanente)] [motivo]
registerAdminCommands('ban', 'admin', function(src, args)
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
end, true)

--- /unban [license]
registerAdminCommands('unban', 'admin', function(src, args)
    local license = args[1]
    if not license then
        return adminNotify(src, 'Uso: ^3/unban [license:xxxxx]^7')
    end

    local affected = MySQL.update.await('DELETE FROM luxury_bans WHERE license = ? OR ip = ? OR identifiers LIKE ?', { license, license, '%' .. license .. '%' })
    if affected and affected > 0 then
        if Security and Security.InvalidateBanCache then
            Security.InvalidateBanCache()
        end
        adminNotify(src, ('^2La licencia %s ha sido desbaneada.^7'):format(license))
        MySQL.insert('INSERT INTO luxury_logs (type, identifier, action) VALUES (?, ?, ?)', {
            'unban', license, ('Desbaneado por %s'):format(src == 0 and 'Consola' or GetPlayerName(src))
        })
    else
        adminNotify(src, '^1No se encontró ningún baneo activo para esa licencia.^7')
    end
end, true)

--- /anticheat [modo: strict|log] (consulta estado o cambia modo en caliente)
registerAdminCommands('anticheat', 'admin', function(src, args)
    local secCfg = Config.Security or {}
    local newMode = args[1]
    if newMode == 'strict' or newMode == 'log' then
        secCfg.Mode = newMode
        Config.Security = secCfg
        adminNotify(src, ('^2Modo de Luxury Sentinel actualizado a: ^3%s^7'):format(newMode))
        return
    end
    adminNotify(src, ('Estado Sentinel: ^2%s^7 | Modo: ^3%s^7 | MaxStrikes: ^3%d^7 | RespawnGrace: ^3%ds^7'):format(
        secCfg.Enabled ~= false and 'ACTIVO' or 'DESACTIVADO',
        secCfg.Mode or 'strict',
        secCfg.MaxStrikes or 3,
        secCfg.TeleportGraceSeconds or 6
    ))
end, true)
