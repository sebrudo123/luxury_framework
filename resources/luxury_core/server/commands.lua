-- luxury_core: Comandos Básicos y de Rol del Servidor (Server Commands)

local function notify(src, msg)
    if src == 0 then
        print(('[luxury_core] %s'):format(msg))
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^5[Luxury]^7', msg } })
    end
end

--- /dinero: Consulta saldo bancario, efectivo, dinero negro y cripto
RegisterCommand('dinero', function(src)
    local player = Core.Players[src]
    if not player then return end
    notify(src, ('Efectivo: ^2$%d^7 | Banco: ^4$%d^7 | Dinero Negro: ^1$%d^7 | Cripto: ^3%d^7'):format(
        player.cash or 0, player.bank or 0, player.black_money or 0, player.crypto or 0
    ))
end, false)

--- /trabajo: Consulta trabajo, grado, estado de servicio y sueldo
RegisterCommand('trabajo', function(src)
    local player = Core.Players[src]
    if not player then return end
    local dutyStr = player:isOnDuty() and '^2En Servicio^7' or '^1Fuera de Servicio^7'
    notify(src, ('Trabajo: ^3%s^7 | Puesto: ^3%s^7 | Sueldo: ^2$%d^7 | Estado: %s'):format(
        player.job.label, player.job.grade_label, player.job.salary, dutyStr
    ))
end, false)

--- /duty o /servicio: Alternar entrada/salida de servicio laboral
local function handleDuty(src)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end

    if player.job.name == 'unemployed' then
        return notify(src, '^1No tienes un empleo asignado actualmente.^7')
    end

    local newState = player:setDuty(not player:isOnDuty())
    if newState then
        notify(src, ('Has entrado ^2EN SERVICIO^7 como %s (%s).'):format(player.job.label, player.job.grade_label))
    else
        notify(src, ('Has salido ^1FUERA DE SERVICIO^7 de %s.'):format(player.job.label))
    end
end
RegisterCommand('duty', handleDuty, false)
RegisterCommand('servicio', handleDuty, false)

--- /logout: Volver al selector Multi-Character si está activo
RegisterCommand('logout', function(src)
    if src == 0 then return end
    if GetResourceState('luxury_multicharacter') ~= 'started' then
        return notify(src, '^1El selector Multi-Character no está activo en este servidor.^7')
    end
    Core.UnloadPlayer(src, true)
end, false)

--- /banda: Consulta afiliación a banda ilegal
RegisterCommand('banda', function(src)
    local player = Core.Players[src]
    if not player then return end
    notify(src, ('Banda: ^1%s^7 | Rango: ^3%s^7'):format(player.gang.label, player.gang.grade_label))
end, false)

--- /id: Muestra documento de identidad, CitizenID y licencias
RegisterCommand('id', function(src)
    local player = Core.Players[src]
    if not player then return end
    local info = player.charinfo
    local lic = info.licences or {}

    local licList = {}
    if lic.driver then licList[#licList + 1] = 'Conducir' end
    if lic.weapon then licList[#licList + 1] = 'Armas' end
    if lic.hunting then licList[#licList + 1] = 'Caza' end
    if lic.pilot then licList[#licList + 1] = 'Aviación' end
    local licStr = #licList > 0 and table.concat(licList, ', ') or 'Ninguna'

    notify(src, ('%s %s | CitizenID: ^3%s^7 | Tel: %s | Trabajo: %s (%s) | Banda: %s | Licencias: ^2%s^7'):format(
        info.firstname, info.lastname, player.citizenid, info.phone,
        player.job.label, player.job.grade_label,
        player.gang.label, licStr
    ))
end, false)

---------------------------------------------------------------------
-- Comandos de Gestión de Bandas (Líderes de Banda)
---------------------------------------------------------------------
local function isGangBoss(src)
    local player = Core.Players[src]
    return player and player.gang and player.gang.isBoss
end

RegisterCommand('contratarBanda', function(src, args)
    if src == 0 then return end
    local boss = Core.Players[src]
    if not boss or not isGangBoss(src) then return notify(src, '^1No eres el líder de una banda.^7') end

    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target then return notify(src, 'Uso: ^3/contratarBanda [id]^7') end

    if target.gang.name ~= 'none' then
        return notify(src, '^1El jugador ya pertenece a otra banda o mafia.^7')
    end

    target:setGang(boss.gang.name, 0)
    notify(src, ('Has reclutado a ^2%s^7 en ^1%s^7.'):format(target.name, boss.gang.label))
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '^1[Banda]^7', ('¡Has sido reclutado en ^1%s^7 como ^3%s^7!'):format(boss.gang.label, target.gang.grade_label) }
    })
end, false)

RegisterCommand('despedirBanda', function(src, args)
    if src == 0 then return end
    local boss = Core.Players[src]
    if not boss or not isGangBoss(src) then return notify(src, '^1No eres el líder de una banda.^7') end

    local targetId = tonumber(args[1])
    local target = Core.Players[targetId]
    if not target or target.gang.name ~= boss.gang.name then
        return notify(src, '^1El jugador no pertenece a tu banda.^7')
    end

    target:setGang('none', 0)
    notify(src, ('Has expulsado a ^3%s^7 de la banda.'):format(target.name))
    TriggerClientEvent('chat:addMessage', targetId, {
        args = { '^1[Banda]^7', ('Has sido expulsado de ^1%s^7.'):format(boss.gang.label) }
    })
end, false)

---------------------------------------------------------------------
-- Comandos de Licencias (Policía y Administración)
---------------------------------------------------------------------
RegisterCommand('darLicencia', function(src, args)
    if src ~= 0 then
        local p = Core.Players[src]
        local isPoliceBoss = p and p.job.name == 'police' and p.job.isBoss
        if not p or (not p:hasGroup('mod') and not isPoliceBoss) then
            return notify(src, '^1No tienes autorización para expedir licencias.^7')
        end
    end

    local targetId = tonumber(args[1])
    local licType = args[2]

    if not targetId or not licType or not Core.Players[targetId] then
        return notify(src, 'Uso: ^3/darLicencia [id] [driver|weapon|hunting|pilot]^7')
    end

    local target = Core.Players[targetId]
    if target:grantLicense(licType) then
        notify(src, ('^2Licencia ^3%s^2 otorgada a %s.^7'):format(licType, target.name))
        TriggerClientEvent('chat:addMessage', targetId, {
            args = { '^2[Licencias]^7', ('Se te ha concedido la licencia de: ^3%s^7'):format(licType) }
        })
    end
end, false)

RegisterCommand('quitarLicencia', function(src, args)
    if src ~= 0 then
        local p = Core.Players[src]
        local isPoliceBoss = p and p.job.name == 'police' and p.job.isBoss
        if not p or (not p:hasGroup('mod') and not isPoliceBoss) then
            return notify(src, '^1No tienes autorización para revocar licencias.^7')
        end
    end

    local targetId = tonumber(args[1])
    local licType = args[2]

    if not targetId or not licType or not Core.Players[targetId] then
        return notify(src, 'Uso: ^3/quitarLicencia [id] [driver|weapon|hunting|pilot]^7')
    end

    local target = Core.Players[targetId]
    if target:revokeLicense(licType) then
        notify(src, ('^1Licencia ^3%s^1 retirada a %s.^7'):format(licType, target.name))
        TriggerClientEvent('chat:addMessage', targetId, {
            args = { '^1[Licencias]^7', ('Se te ha retirado la licencia de: ^3%s^7'):format(licType) }
        })
    end
end, false)

---------------------------------------------------------------------
-- Comandos de Chat Roleplay, Emergencias y Reportes
---------------------------------------------------------------------

--- Helper compartido para envíos de chat/3D por proximidad
local function broadcastProximity(src, radius, chatPrefix, text, overheadType)
    local ped = GetPlayerPed(src)
    if not ped or not DoesEntityExist(ped) then return end
    local coords = GetEntityCoords(ped)

    for _, targetPlayer in pairs(Core.Players) do
        local targetPed = GetPlayerPed(targetPlayer.source)
        if targetPed and DoesEntityExist(targetPed) then
            if #(coords - GetEntityCoords(targetPed)) <= radius then
                TriggerClientEvent('chat:addMessage', targetPlayer.source, {
                    args = { chatPrefix, text }
                })
                if overheadType then
                    TriggerClientEvent('luxury:client:show3DText', targetPlayer.source, src, text, overheadType)
                end
            end
        end
    end
end

local function getRpName(player)
    return player.name or (player.charinfo and (player.charinfo.firstname .. ' ' .. player.charinfo.lastname) or 'Ciudadano')
end

-- /me [accion del personaje]
RegisterCommand('me', function(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/me [acción]^7') end

    local action = table.concat(args, ' ')
    broadcastProximity(src, 15.0, ('^6* %s^7'):format(getRpName(player)), action, 'me')
    if Logger and Logger.LogChat then Logger.LogChat(src, '/me', action) end
end, false)

-- /do [entorno o circunstancia]
RegisterCommand('do', function(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/do [entorno / situación]^7') end

    local action = table.concat(args, ' ')
    broadcastProximity(src, 15.0, ('^4* [DO] %s^7'):format(getRpName(player)), action, 'do')
    if Logger and Logger.LogChat then Logger.LogChat(src, '/do', action) end
end, false)

-- /dado [caras opcional, por defecto 6]
RegisterCommand('dado', function(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end

    local sides = math.max(2, math.min(100, math.floor(tonumber(args[1]) or 6)))
    local roll = math.random(1, sides)
    local text = ('ha lanzado un dado de %d caras y ha sacado: %d'):format(sides, roll)
    broadcastProximity(src, 15.0, ('^6* %s^7'):format(getRpName(player)), text, 'me')
end, false)

-- /intentar [acción] (50/50 azar RP)
RegisterCommand('intentar', function(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/intentar [acción]^7') end

    local action = table.concat(args, ' ')
    local success = math.random(1, 2) == 1
    local outcome = success and '[ÉXITO]' or '[FALLO]'
    local text = ('intenta %s -> %s'):format(action, outcome)
    broadcastProximity(src, 15.0, ('^6* %s^7'):format(getRpName(player)), text, success and 'me' or 'do')
end, false)

-- /ooc [mensaje] (o /b)
local function handleOOC(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/ooc [mensaje]^7') end

    local msg = table.concat(args, ' ')
    broadcastProximity(src, 20.0, ('^7[OOC | %s (ID: %d)]^7'):format(getRpName(player), src), msg, nil)
    if Logger and Logger.LogChat then Logger.LogChat(src, '/ooc', msg) end
end
RegisterCommand('ooc', handleOOC, false)
RegisterCommand('b', handleOOC, false)

-- /twt [mensaje] (o /tweet)
local function handleTweet(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/twt [mensaje]^7') end

    local msg = table.concat(args, ' ')
    local handle = player.charinfo and (player.charinfo.firstname .. '_' .. player.charinfo.lastname) or player.name
    TriggerClientEvent('chat:addMessage', -1, {
        args = { ('^5[Twitter | @%s]^7'):format(handle), msg }
    })
    if Logger and Logger.LogChat then Logger.LogChat(src, '/twt', msg) end
end
RegisterCommand('twt', handleTweet, false)
RegisterCommand('tweet', handleTweet, false)

-- /anon [mensaje]
RegisterCommand('anon', function(src, args)
    if src == 0 then return end
    if #args == 0 then return notify(src, 'Uso: ^3/anon [mensaje anónimo]^7') end

    local msg = table.concat(args, ' ')
    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^1[Anónimo]^7', msg }
    })
    if Logger and Logger.LogChat then Logger.LogChat(src, '/anon', msg) end
end, false)

-- /911 o /entorno [descripción de emergencia]
local function handleEmergencyCall(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/911 [descripción de la emergencia]^7') end

    local msg = table.concat(args, ' ')
    local ped = GetPlayerPed(src)
    local coords = ped ~= 0 and GetEntityCoords(ped) or vector3(0.0, 0.0, 0.0)
    local dispatched = 0

    for _, targetPlayer in pairs(Core.Players) do
        local jName = targetPlayer.job and targetPlayer.job.name
        if (jName == 'police' or jName == 'ambulance') and targetPlayer:isOnDuty() then
            TriggerClientEvent('chat:addMessage', targetPlayer.source, {
                args = { ('^1[CENTRAL 911 | ID: %d]^7'):format(src), msg }
            })
            TriggerClientEvent('luxury:client:dispatchAlert', targetPlayer.source, coords, ('Aviso 911: %s'):format(msg))
            dispatched = dispatched + 1
        end
    end

    notify(src, ('^2Tu llamada al 911 ha sido transmitida a las centrales de emergencia (%d unidades en servicio).^7'):format(dispatched))
    if Logger and Logger.LogChat then Logger.LogChat(src, '/911', msg) end
end
RegisterCommand('911', handleEmergencyCall, false)
RegisterCommand('entorno', handleEmergencyCall, false)

-- /report [mensaje]: Envía un reporte a todos los moderadores y administradores conectados
RegisterCommand('report', function(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end
    if #args == 0 then return notify(src, 'Uso: ^3/report [describe tu problema]^7') end

    local msg = table.concat(args, ' ')
    local staffNotified = 0
    for targetId, targetPlayer in pairs(Core.Players) do
        if targetPlayer:hasGroup('mod') then
            TriggerClientEvent('chat:addMessage', targetId, {
                args = { ('^1[REPORTE | %s (ID: %d)]^7'):format(player.name, src), msg .. ' ^3(/reply ' .. src .. ' ...)^7' }
            })
            staffNotified = staffNotified + 1
        end
    end

    notify(src, ('^2Reporte enviado correctamente (%d miembros del staff en línea).^7'):format(staffNotified))
    if Logger and Logger.LogReport then Logger.LogReport(src, msg) end
end, false)

--- /pagar [id] [cantidad] o /transferir [id] [cantidad]: Pago en efectivo mano a mano (<= 4m)
local function handlePayCash(src, args)
    if src == 0 then return end
    local player = Core.Players[src]
    if not player then return end

    local targetId = tonumber(args[1])
    local amount = math.floor(tonumber(args[2]) or 0)
    if not targetId or amount <= 0 or amount > 2147483647 then
        return notify(src, 'Uso: ^3/pagar [id] [cantidad]^7')
    end

    if targetId == src then
        return notify(src, '^1No puedes pagarte efectivo a ti mismo.^7')
    end

    local target = Core.Players[targetId]
    if not target then
        return notify(src, '^1El jugador no está conectado.^7')
    end

    local myPed = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetId)
    if myPed == 0 or tPed == 0 or #(GetEntityCoords(myPed) - GetEntityCoords(tPed)) > 4.0 then
        return notify(src, '^1Debes estar a menos de 4 metros de la persona para entregarle efectivo.^7')
    end

    if player:removeMoney('cash', amount, ('Pago en efectivo a %s'):format(target.name)) then
        target:addMoney('cash', amount, ('Pago en efectivo de %s'):format(player.name))
        notify(src, ('Has entregado ^2$%d^7 en efectivo a ^3%s^7.'):format(amount, target.name))
        notify(targetId, ('Has recibido ^2$%d^7 en efectivo de ^3%s^7.'):format(amount, player.name))
    else
        notify(src, '^1No tienes suficiente dinero en efectivo.^7')
    end
end
RegisterCommand('pagar', handlePayCash, false)
RegisterCommand('transferir', handlePayCash, false)

--- /ayuda o /comandos: Lista rápida de comandos disponibles
local function handleHelp(src)
    if src == 0 then return end
    notify(src, '^3Rol:^7 /me, /do, /ooc (/b), /twt, /anon, /dado, /intentar, /911 (/entorno)')
    notify(src, '^3Personaje:^7 /dinero, /pagar [id] [monto], /trabajo, /duty, /banda, /id, /report, /logout')
end
RegisterCommand('ayuda', handleHelp, false)
RegisterCommand('comandos', handleHelp, false)
