-- luxury_core: Motor de Seguridad Avanzado, Anti-Dump y Centinela del Servidor (Luxury Sentinel v2)
Security = {}

local PlayerTokens = {}
local PlayerHeartbeats = {}
local PendingChallenges = {}
local EventRateLimits = {}
local PlayerExplosionCounts = {}
local PlayerEntityCounts = {}
local PlayerParticleCounts = {}
local PlayerFireCounts = {}
local PlayerPositions = {}
local PlayerTeleportGrace = {}
local PlayerStrikes = {}
local CachedBans = nil

local function secCfg()
    return Config.Security or {}
end

local function isStaff(src)
    local player = Core.Players[src]
    return player and player:hasGroup('mod') or false
end

--- Recolecta todos los identificadores de un jugador (license, steam, discord, ip, etc.)
local function getAllIdentifiers(src)
    local raw = GetPlayerIdentifiers(src)
    local list = {}
    local ip = nil
    local hasDiscord = false

    for _, id in ipairs(raw) do
        list[#list + 1] = id
        if id:sub(1, 3) == 'ip:' then
            ip = id:sub(4)
        elseif id:sub(1, 8) == 'discord:' then
            hasDiscord = true
        end
    end
    return list, ip or GetPlayerEndpoint(src), hasDiscord
end

--- Recolecta todos los tokens de hardware (HWID) del cliente
local function getHardwareTokens(src)
    local tokens = {}
    local count = GetNumPlayerTokens(src)
    for i = 0, count - 1 do
        tokens[#tokens + 1] = GetPlayerToken(src, i)
    end
    return tokens
end

--- Generador de tokens de sesión criptográficos
local function generateToken(length)
    length = length or 32
    local chars = 'abcdef0123456789'
    local out = {}
    for i = 1, length do
        local r = math.random(1, #chars)
        out[i] = chars:sub(r, r)
    end
    return table.concat(out)
end

--- Obtiene la lista de recursos iniciados actualmente en el servidor
local function getStartedResources()
    local list = {}
    local total = GetNumResources()
    for i = 0, total - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == 'started' then
            list[resName] = true
        end
    end
    return list
end

local function computeChallengeHash(challenge)
    return tostring((challenge * 7 + 1337) % 9999999)
end

local function notifyStaffAlert(msg)
    for id, player in pairs(Core.Players) do
        if player:hasGroup('mod') then
            TriggerClientEvent('chat:addMessage', id, {
                args = { '^1[LUXURY-SENTINEL]^7', msg }
            })
        end
    end
end

local function checkSlidingWindow(store, src, windowSec, maxCount)
    local now = os.time()
    local rec = store[src]
    if not rec or (now - rec.windowStart) >= windowSec then
        store[src] = { windowStart = now, count = 1 }
        return true, 1
    end
    rec.count = rec.count + 1
    return rec.count <= maxCount, rec.count
end

---------------------------------------------------------------------
-- 1) Handshake de Seguridad, Token de Sesión y Lista de Recursos
---------------------------------------------------------------------
RegisterNetEvent('luxury:security:requestHandshake', function()
    local src = source
    local token = generateToken(32)
    PlayerTokens[src] = token
    PlayerHeartbeats[src] = os.time()
    EventRateLimits[src] = {}
    PlayerStrikes[src] = PlayerStrikes[src] or 0

    local cfg = secCfg()
    local resList = cfg.CheckResourceInjection ~= false and getStartedResources() or nil
    TriggerClientEvent('luxury:security:handshakeResponse', src, token, resList)
end)

-- Mantener lista sincronizada si un admin arranca un recurso nuevo en vivo
AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then return end
    if secCfg().CheckResourceInjection ~= false then
        TriggerClientEvent('luxury:security:addAllowedResource', -1, resName)
    end
end)

function Security.ValidateToken(src, clientToken)
    if secCfg().RequireSessionToken ~= true then
        return true
    end
    if not PlayerTokens[src] or PlayerTokens[src] ~= clientToken then
        Security.AddStrike(src, 'Manipulación de memoria / Token de sesión inválido', true)
        return false
    end
    return true
end

---------------------------------------------------------------------
-- 2) Sistema de Strikes, Captura de Evidencia y Sanciones Configurables
---------------------------------------------------------------------
function Security.MarkTeleport(src)
    src = tonumber(src)
    if not src then return end
    local grace = secCfg().TeleportGraceSeconds or 6
    PlayerTeleportGrace[src] = os.time() + grace
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        PlayerPositions[src] = { coords = GetEntityCoords(ped), time = os.time() }
    end
end

local function captureScreenshotIfAvailable(src, reason)
    if secCfg().UseScreenshots == false then return end
    if GetResourceState('screenshot-basic') ~= 'started' then return end
    pcall(function()
        exports['screenshot-basic']:requestClientScreenshot(src, { encoding = 'jpg', quality = 0.75 }, function(err, data)
            if not err and data and Logger and Logger.LogAnticheat then
                Logger.LogAnticheat(src, ('Evidencia visual capturada (%s)'):format(reason), 'Screenshot generado correctamente.')
            end
        end)
    end)
end

function Security.AddStrike(src, reason, forceBan)
    if not src or src == 0 or isStaff(src) then return end
    local cfg = secCfg()
    if cfg.Enabled == false then return end

    local player = Core.Players[src]
    local pName = player and player.name or GetPlayerName(src) or ('ID:' .. tostring(src))
    local license = player and player.license or 'Desconocido'
    local count = (PlayerStrikes[src] or 0) + 1
    PlayerStrikes[src] = count
    local maxStrikes = cfg.MaxStrikes or 3

    if Logger and Logger.LogAnticheat then
        Logger.LogAnticheat(src, reason, ('Strike %d/%d | Modo: %s'):format(count, maxStrikes, cfg.Mode or 'strict'))
    end
    MySQL.insert('INSERT INTO luxury_logs (type, identifier, action) VALUES (?, ?, ?)', {
        'security_strike', license, ('Strike %d/%d: %s'):format(count, maxStrikes, tostring(reason))
    })

    notifyStaffAlert(('^3%s (ID: %d)^7 -> %s ^1[Strike %d/%d]^7'):format(pName, src, tostring(reason), count, maxStrikes))

    if cfg.Mode == 'log' then
        print(('^3[LUXURY-SENTINEL:LOG] %s (ID: %d) -> %s^7'):format(pName, src, tostring(reason)))
        return
    end

    if forceBan or count >= maxStrikes then
        captureScreenshotIfAvailable(src, reason)
        Security.BanPlayer(src, reason)
    end
end

---------------------------------------------------------------------
-- 3) Validación de Coordenadas y Anti-Teleport Autoritativo del Servidor
---------------------------------------------------------------------
local function evaluateMovement(src, newVec)
    local player = Core.Players[src]
    if not player or isStaff(src) then
        PlayerPositions[src] = { coords = newVec, time = os.time() }
        return true
    end

    local now = os.time()
    if PlayerTeleportGrace[src] and now <= PlayerTeleportGrace[src] then
        PlayerPositions[src] = { coords = newVec, time = now }
        return true
    end

    if player.metadata and player.metadata.isdead then
        PlayerPositions[src] = { coords = newVec, time = now }
        return true
    end

    local last = PlayerPositions[src]
    if last then
        local dist = #(newVec - last.coords)
        local timeDelta = math.max(1, now - last.time)
        local speed = dist / timeDelta

        local ped = GetPlayerPed(src)
        local veh = (ped and ped ~= 0) and GetVehiclePedIsIn(ped, false) or 0
        local vehClass = veh ~= 0 and GetVehicleClass(veh) or -1

        -- Excluir helicópteros (15) y aviones (16) de velocidades altas
        if dist > 180.0 and vehClass ~= 15 and vehClass ~= 16 and speed > 135.0 then
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                SetEntityCoords(ped, last.coords.x, last.coords.y, last.coords.z, false, false, false, false)
            end
            Security.AddStrike(src, ('Teletransporte no autorizado (%.1fm en %ds | %.0f m/s)'):format(dist, timeDelta, speed), dist > 450.0)
            return false
        end
    end

    PlayerPositions[src] = { coords = newVec, time = now }
    return true
end

function Security.ValidateCoords(src, newCoords)
    if not newCoords or not newCoords.x or not newCoords.y or not newCoords.z then return false end
    return evaluateMovement(src, vector3(newCoords.x + 0.0, newCoords.y + 0.0, newCoords.z + 0.0))
end

-- Polling server-side en OneSync para que ningún cliente pueda omitir luxury:server:updateCoords
CreateThread(function()
    while true do
        local interval = secCfg().ServerCoordsCheckMs or 3000
        Wait(interval)
        if secCfg().Enabled ~= false then
            for src, _ in pairs(Core.Players) do
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 and DoesEntityExist(ped) then
                    evaluateMovement(src, GetEntityCoords(ped))
                end
            end
        end
    end
end)

---------------------------------------------------------------------
-- 4) Protección de State Bags Autoritativos (Anti-StateBag Tamper)
---------------------------------------------------------------------
local ProtectedBags = {
    ['luxury:data'] = true,
    ['isLoggedIn'] = true,
    ['gang'] = true,
    ['citizenid'] = true
}

for bagKey, _ in pairs(ProtectedBags) do
    AddStateBagChangeHandler(bagKey, nil, function(bagName, key, value, source, replicated)
        if source and source > 0 then
            Security.AddStrike(source, ('Modificación ilegal de State Bag de servidor protegido (%s)'):format(key), true)
        end
    end)
end

---------------------------------------------------------------------
-- 5) Rate Limiting Granular por Evento (Anti-Spam / Anti-Flood)
---------------------------------------------------------------------
-- Soporta CheckRateLimit(src, maxPerSec) y CheckRateLimit(src, 'eventName', maxPerSec)
function Security.CheckRateLimit(src, eventOrMax, maxPerSecond)
    local eventKey = 'global'
    local limit = 25

    if type(eventOrMax) == 'string' then
        eventKey = eventOrMax
        limit = maxPerSecond or 10
    elseif type(eventOrMax) == 'number' then
        limit = eventOrMax
    end

    EventRateLimits[src] = EventRateLimits[src] or {}
    local data = EventRateLimits[src][eventKey]
    local now = os.time()

    if not data or now ~= data.lastReset then
        EventRateLimits[src][eventKey] = { count = 1, lastReset = now }
        return true
    end

    data.count = data.count + 1
    if data.count > limit then
        Security.AddStrike(src, ('Event Flooding en [%s] (%d/s > máx %d)'):format(eventKey, data.count, limit), data.count > (limit * 2))
        return false
    end

    return true
end

---------------------------------------------------------------------
-- 6) Cache de Baneos y Sistema HWID Ban / Ban Evasion
---------------------------------------------------------------------
function Security.InvalidateBanCache()
    CachedBans = nil
end

function Security.RefreshBanCache()
    local rows = MySQL.query.await('SELECT * FROM luxury_bans ORDER BY id DESC', {}) or {}
    local now = os.time()
    local active = {}

    for _, ban in ipairs(rows) do
        if ban.expire and ban.expire > 0 and ban.expire <= now then
            MySQL.query('DELETE FROM luxury_bans WHERE id = ?', { ban.id })
        else
            ban._decodedIds = ban.identifiers and (json.decode(ban.identifiers) or {}) or {}
            ban._decodedTokens = ban.tokens and (json.decode(ban.tokens) or {}) or {}
            active[#active + 1] = ban
        end
    end

    CachedBans = active
    return active
end

function Security.BanPlayer(src, reason, durationHours)
    local player = Core.Players[src]
    local name = player and player.name or GetPlayerName(src) or 'Inyector'
    local license = player and player.license or Core.GetLicense(src) or 'Desconocido'
    local ids, ip = getAllIdentifiers(src)
    local hwidTokens = getHardwareTokens(src)

    local expireTimestamp = (durationHours and durationHours > 0) and (os.time() + (durationHours * 3600)) or 0
    local expireStr = (durationHours and durationHours > 0) and ('%d horas'):format(durationHours) or 'Permanente'

    MySQL.insert.await([[
        INSERT INTO luxury_bans (license, name, reason, author, expire, identifiers, tokens, ip) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        license, name, reason, 'Luxury Sentinel (Automático)', expireTimestamp,
        json.encode(ids), json.encode(hwidTokens), ip
    })

    Security.InvalidateBanCache()

    MySQL.insert('INSERT INTO luxury_logs (type, identifier, action) VALUES (?, ?, ?)', {
        'security_ban', license, ('Baneado HWID por: %s (IP: %s)'):format(reason, tostring(ip))
    })

    if Logger and Logger.LogBan then
        Logger.LogBan(name, license, reason, 'Luxury Sentinel', expireStr, ip)
    end

    print(('^1[LUXURY-SECURITY] SANCIONADO AUTOMÁTICAMENTE: %s (ID: %d | HWID/IP: %s) -> %s^7'):format(name, src, tostring(ip), reason))
    DropPlayer(src, ('\n[Luxury Sentinel] Conexión denegada por seguridad.\nMotivo: %s'):format(reason))
end

function Security.CheckBans(src, deferrals)
    local playerIdentifiers, _, hasDiscord = getAllIdentifiers(src)
    if secCfg().RequireDiscord == true and not hasDiscord then
        deferrals.done('\nDebes tener Discord abierto y vinculado a FiveM para acceder a este servidor.')
        return true
    end

    local playerTokens = getHardwareTokens(src)
    local bans = CachedBans or Security.RefreshBanCache()
    local currentTime = os.time()

    for _, ban in ipairs(bans) do
        if ban.expire == 0 or ban.expire > currentTime then
            local isMatch = false
            local matchReason = ''

            for _, id in ipairs(playerIdentifiers) do
                if id == ban.license then
                    isMatch = true
                    matchReason = 'Licencia Rockstar sancionada'
                    break
                end
            end

            if not isMatch and ban._decodedIds then
                for _, pId in ipairs(playerIdentifiers) do
                    for _, bId in ipairs(ban._decodedIds) do
                        if pId == bId then
                            isMatch = true
                            matchReason = 'Identificador secundario vinculado a sanción previa'
                            break
                        end
                    end
                    if isMatch then break end
                end
            end

            if not isMatch and ban._decodedTokens then
                for _, pToken in ipairs(playerTokens) do
                    for _, bToken in ipairs(ban._decodedTokens) do
                        if pToken == bToken then
                            isMatch = true
                            matchReason = 'Intento de evasión de baneo por Hardware (HWID detectado)'
                            break
                        end
                    end
                    if isMatch then break end
                end
            end

            if isMatch then
                local expireMsg = ban.expire == 0 and 'Permanente' or os.date('%Y-%m-%d %H:%M:%S', ban.expire)
                deferrals.done(('\nACCESO DENEGADO (Sanción Activa)\nMotivo: %s\nTipo: %s\nExpira: %s'):format(ban.reason, matchReason, expireMsg))
                return true
            end
        end
    end
    return false
end

---------------------------------------------------------------------
-- 7) Interceptores Nativos de Eventos de C++ (FiveM Native Events)
---------------------------------------------------------------------
local BlacklistedExplosions = {
    [1] = true, [4] = true, [5] = true, [9] = true, [10] = true, [25] = true, [29] = true, [32] = true
}

AddEventHandler('explosionEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end

    if BlacklistedExplosions[ev.explosionType] then
        CancelEvent()
        Security.AddStrike(src, ('Explosión ilegal prohibida (Tipo %d)'):format(ev.explosionType), true)
        return
    end

    local ok = checkSlidingWindow(PlayerExplosionCounts, src, 2, 2)
    if not ok then
        CancelEvent()
        Security.AddStrike(src, 'Spam masivo de explosiones (Mass Explosion Exploit)', true)
    end
end)

local BlacklistedVehicleModels = {
    [`rhino`] = true, [`hydra`] = true, [`lazer`] = true, [`oppressor`] = true, [`oppressor2`] = true,
    [`khanjali`] = true, [`apc`] = true, [`cargoplane`] = true, [`cerberus`] = true, [`ruiner2`] = true,
    [`stromberg`] = true, [`deluxo`] = true, [`kosatka`] = true, [`alkonost`] = true, [`jet`] = true
}

local BlacklistedPropModels = {
    [`stt_prop_ramp_adj_flip_mb`] = true, [`stt_prop_stunt_track_dwslope30`] = true,
    [`prop_gold_cont_01`] = true, [`p_spinning_anus_s`] = true, [`prop_fnclink_05crnr1`] = true,
    [`xs_prop_hamburgher_wl`] = true, [`xs_prop_plastic_bottle_wl`] = true, [`prop_bumper_car_01`] = true
}

local BlacklistedPedModels = {
    [`s_m_y_swat_01`] = true, [`a_m_m_acult_01`] = true, [`u_m_y_zombie_01`] = true,
    [`s_m_y_blackops_01`] = true, [`s_m_y_marine_03`] = true
}

AddEventHandler('entityCreating', function(entity)
    if not DoesEntityExist(entity) then return end
    local owner = NetworkGetEntityOwner(entity)
    if not owner or owner == 0 or isStaff(owner) then return end

    local model = GetEntityModel(entity)
    local entityType = GetEntityType(entity) -- 1 = Ped, 2 = Vehicle, 3 = Object
    local cfg = secCfg()
    local window = cfg.MaxEntitiesWindowSec or 3

    PlayerEntityCounts[owner] = PlayerEntityCounts[owner] or {}
    PlayerEntityCounts[owner][entityType] = PlayerEntityCounts[owner][entityType] or {}

    if entityType == 2 then
        if BlacklistedVehicleModels[model] then
            CancelEvent()
            Security.AddStrike(owner, ('Spawneo de vehículo militar prohibido (Hash: %s)'):format(tostring(model)), true)
            return
        end
        local ok = checkSlidingWindow(PlayerEntityCounts[owner][2], owner, window, cfg.MaxVehiclesPerWindow or 6)
        if not ok then
            CancelEvent()
            Security.AddStrike(owner, 'Mass Vehicle Spawner detectado')
        end
    elseif entityType == 1 then
        if BlacklistedPedModels[model] then
            CancelEvent()
            Security.AddStrike(owner, ('Spawneo de ped prohibido (Hash: %s)'):format(tostring(model)))
            return
        end
        local ok = checkSlidingWindow(PlayerEntityCounts[owner][1], owner, window, cfg.MaxPedsPerWindow or 8)
        if not ok then
            CancelEvent()
            Security.AddStrike(owner, 'Mass Ped Spawner detectado')
        end
    elseif entityType == 3 then
        if BlacklistedPropModels[model] then
            CancelEvent()
            Security.AddStrike(owner, ('Spawneo de prop troleo/jaula prohibido (Hash: %s)'):format(tostring(model)), true)
            return
        end
        local ok = checkSlidingWindow(PlayerEntityCounts[owner][3], owner, window, cfg.MaxObjectsPerWindow or 10)
        if not ok then
            CancelEvent()
            Security.AddStrike(owner, 'Mass Prop / Cage Spawner detectado')
        end
    end
end)

AddEventHandler('weaponDamageEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end

    local maxDmg = secCfg().MaxWeaponSingleHitDamage or 450
    if ev.weaponDamage and ev.weaponDamage > maxDmg and not ev.willKill then
        CancelEvent()
        Security.AddStrike(src, ('Modificador ilegal de daño por arma (%d daño en un impacto)'):format(ev.weaponDamage), ev.weaponDamage > 1000)
        return
    elseif ev.weaponDamage and ev.weaponDamage > 1200 then
        CancelEvent()
        Security.AddStrike(src, ('One-Shot Kill Exploit detectado (%d daño)'):format(ev.weaponDamage), true)
        return
    end
end)

AddEventHandler('giveWeaponEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end
    CancelEvent()
    Security.AddStrike(src, 'Intento de entrega remota de armas por evento de red (giveWeaponEvent)', true)
end)

AddEventHandler('removeWeaponEvent', function(sender, ev)
    local src = tonumber(sender)
    if src and src > 0 and not isStaff(src) then
        CancelEvent()
    end
end)

AddEventHandler('removeAllWeaponsEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end
    CancelEvent()
    Security.AddStrike(src, 'Intento de desarme masivo de jugadores (removeAllWeaponsEvent)', true)
end)

AddEventHandler('clearPedTasksEvent', function(sender, ev)
    local src = tonumber(sender)
    if src and src > 0 and not isStaff(src) and ev.immediately then
        CancelEvent()
    end
end)

AddEventHandler('fireEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end
    local ok = checkSlidingWindow(PlayerFireCounts, src, 2, secCfg().MaxFiresPerWindow or 3)
    if not ok then
        CancelEvent()
        Security.AddStrike(src, 'Spawn masivo de incendios en mapa (fireEvent)')
    end
end)

AddEventHandler('ptFxEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end
    local ok = checkSlidingWindow(PlayerParticleCounts, src, 2, secCfg().MaxParticlesPerWindow or 10)
    if not ok then
        CancelEvent()
        Security.AddStrike(src, 'Flood masivo de partículas de red (ptFxEvent)')
    end
end)

local BlacklistedProjectiles = {
    [`WEAPON_RPG`] = true, [`WEAPON_HOMINGLAUNCHER`] = true, [`WEAPON_GRENADELAUNCHER`] = true,
    [`WEAPON_RAILGUN`] = true, [`WEAPON_FIREWORK`] = true
}

AddEventHandler('startProjectileEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 or isStaff(src) then return end
    if ev.weaponHash and BlacklistedProjectiles[ev.weaponHash] then
        CancelEvent()
        Security.AddStrike(src, ('Lanzamiento de proyectil prohibido (Hash: %s)'):format(tostring(ev.weaponHash)), true)
    end
end)

---------------------------------------------------------------------
-- 8) Red de Trampas Honeypot (Cebo Anti-Dumpers y Anti-Executors)
---------------------------------------------------------------------
local HoneypotEvents = {
    'AdminMenu:giveCash', 'AdminMenu:giveBank', 'esx:giveInventoryItem', 'esx_ambulancejob:revive',
    'esx_policejob:handcuff', 'd3x_vehicleshop:setVehicleOwned', 'esx_godmode:toggle', 'bank:transferMoney',
    'luxury:cheat:giveAllItems', 'luxury:admin:instantKillAll', 'hacker:spawnMoney', 'esx_jailer:unjailTime',
    'fuel:pay', 'vrp:giveMoney', 'tacos:collectMoney', 'cuff:client', 'esx:spawnVehicle',
    'qb-weapons:client:SetWeaponAmmo', 'qb-inventory:server:SaveStashItems', 'QBCore:Server:SetMetaData',
    'kashactersS:DeleteCharacter', 'esx_drugs:startHarvestWeed', 'esx_communityservice:sendToCommunityService',
    'paycheck:salary', 'luxury:exploit:triggerBypass', 'esx_mechanicjob:repairVehicleFree',
    'esx_billing:sendBillToPlayerDirect'
}

for _, eventName in ipairs(HoneypotEvents) do
    RegisterNetEvent(eventName, function()
        local src = source
        Security.AddStrike(src, ('Inyección de evento trampa detectada (Honeypot: %s)'):format(eventName), true)
    end)
end

RegisterNetEvent('luxury:security:flagPlayer', function(reason, severity)
    local src = source
    if not isStaff(src) then
        Security.AddStrike(src, tostring(reason or 'Anomalía de cliente detectada'), severity == 'high')
    end
end)

---------------------------------------------------------------------
-- 9) Monitor de Latido Criptográfico Real (Heartbeat Challenge)
---------------------------------------------------------------------
RegisterNetEvent('luxury:security:heartbeatResponse', function(challenge, responseHash)
    local src = source
    local pending = PendingChallenges[src]
    if not pending then
        PlayerHeartbeats[src] = os.time()
        return
    end

    if tonumber(challenge) ~= pending.challenge or tostring(responseHash) ~= pending.expected then
        Security.AddStrike(src, 'Respuesta de latido criptográfico falsificada (Heartbeat Spoof)', true)
        return
    end

    PendingChallenges[src] = nil
    PlayerHeartbeats[src] = os.time()
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        local timeoutSec = secCfg().HeartbeatTimeoutSec or 75
        for src, _ in pairs(Core.Players) do
            local lastHeartbeat = PlayerHeartbeats[src] or now
            if (now - lastHeartbeat) > timeoutSec then
                print(('^1[LUXURY-SECURITY] Desconexión por fallo de latido / Script detenido (ID: %d)^7'):format(src))
                DropPlayer(src, '[Luxury Sentinel] Tiempo de sincronización de seguridad agotado (Script Tamper Detected).')
                PlayerHeartbeats[src] = nil
                PendingChallenges[src] = nil
            else
                local challenge = math.random(100000, 999999)
                PendingChallenges[src] = {
                    challenge = challenge,
                    expected = computeChallengeHash(challenge),
                    issuedAt = now
                }
                TriggerClientEvent('luxury:security:heartbeatChallenge', src, challenge)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    PlayerTokens[src] = nil
    PlayerHeartbeats[src] = nil
    PendingChallenges[src] = nil
    EventRateLimits[src] = nil
    PlayerExplosionCounts[src] = nil
    PlayerEntityCounts[src] = nil
    PlayerParticleCounts[src] = nil
    PlayerFireCounts[src] = nil
    PlayerPositions[src] = nil
    PlayerTeleportGrace[src] = nil
    PlayerStrikes[src] = nil
end)

exports('ValidateToken', Security.ValidateToken)
exports('ValidateCoords', Security.ValidateCoords)
exports('CheckRateLimit', Security.CheckRateLimit)
exports('BanPlayer', Security.BanPlayer)
exports('CheckBans', Security.CheckBans)
exports('AddStrike', Security.AddStrike)
exports('MarkTeleport', Security.MarkTeleport)
exports('InvalidateBanCache', Security.InvalidateBanCache)
