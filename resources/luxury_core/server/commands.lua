-- luxury_core: Comandos Básicos y de Rol del Servidor (Server Commands)

local function notify(src, msg)
    if src == 0 then
        print(('[luxury_core] %s'):format(msg))
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^5[Luxury]^7', msg } })
    end
end

--- /dinero: Consulta saldo bancario y efectivo
RegisterCommand('dinero', function(src)
    local player = Core.Players[src]
    if not player then return end
    notify(src, ('Efectivo: ^2$%s^7 | Banco: ^4$%s^7'):format(player.cash, player.bank))
end, false)

--- /trabajo: Consulta trabajo, grado y sueldo
RegisterCommand('trabajo', function(src)
    local player = Core.Players[src]
    if not player then return end
    notify(src, ('Trabajo: ^3%s^7 | Puesto: ^3%s^7 | Sueldo: ^2$%d^7'):format(player.job.label, player.job.grade_label, player.job.salary))
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
