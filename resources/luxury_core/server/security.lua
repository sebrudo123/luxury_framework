-- luxury_core: Motor de Seguridad Avanzado, Anti-Dump y Centinela del Servidor
Security = {}
local PlayerTokens = {}
local PlayerHeartbeats = {}
local EventRateLimits = {}
local PlayerExplosionCounts = {}
local PlayerPositions = {}

--- Recolecta todos los identificadores de un jugador (license, steam, discord, ip, etc.)
local function getAllIdentifiers(src)
    local raw = GetPlayerIdentifiers(src)
    local list = {}
    local ip = nil

    for _, id in ipairs(raw) do
        list[#list + 1] = id
        if id:sub(1, 3) == 'ip:' then
            ip = id:sub(4)
        end
    end
    return list, ip or GetPlayerEndpoint(src)
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
    local token = ''
    for _ = 1, length do
        local r = math.random(1, #chars)
        token = token .. chars:sub(r, r)
    end
    return token
end

---------------------------------------------------------------------
-- 1) Handshake de Seguridad y Token de Sesión
---------------------------------------------------------------------
RegisterNetEvent('luxury:security:requestHandshake', function()
    local src = source
    local token = generateToken(32)
    PlayerTokens[src] = token
    PlayerHeartbeats[src] = os.time()
    EventRateLimits[src] = { count = 0, lastReset = os.time() }

    TriggerClientEvent('luxury:security:handshakeResponse', src, token)
end)

function Security.ValidateToken(src, clientToken)
    if not PlayerTokens[src] or PlayerTokens[src] ~= clientToken then
        Security.BanPlayer(src, 'Manipulación de memoria / Token de sesión inválido')
        return false
    end
    return true
end

---------------------------------------------------------------------
-- 2) Validación de Coordenadas y Anti-Teleport del Servidor
---------------------------------------------------------------------
function Security.ValidateCoords(src, newCoords)
    if not newCoords or not newCoords.x or not newCoords.y or not newCoords.z then return false end

    local player = Core.Players[src]
    if not player then return true end

    -- Administradores en noclip tienen bypass
    if player:hasGroup('mod') then
        PlayerPositions[src] = { coords = vector3(newCoords.x, newCoords.y, newCoords.z), time = os.time() }
        return true
    end

    local last = PlayerPositions[src]
    local now = os.time()

    if last then
        local currentVec = vector3(newCoords.x, newCoords.y, newCoords.z)
        local dist = #(currentVec - last.coords)
        local timeDelta = math.max(1, now - last.time)
        local speed = dist / timeDelta -- m/s

        -- Si no está en aeronave o caída libre y la velocidad supera 150 m/s (540 km/h)
        local ped = GetPlayerPed(src)
        local veh = GetVehiclePedIsIn(ped, false)
        local vehClass = veh ~= 0 and GetVehicleClass(veh) or -1

        -- 15: Helicópteros, 16: Aviones
        if dist > 200.0 and vehClass ~= 15 and vehClass ~= 16 and speed > 150.0 then
            Security.BanPlayer(src, ('Teletransporte ilegal detectado (Distancia: %.1fm en %ds)'):format(dist, timeDelta))
            return false
        end
    end

    PlayerPositions[src] = { coords = vector3(newCoords.x, newCoords.y, newCoords.z), time = now }
    return true
end

---------------------------------------------------------------------
-- 3) Protección de State Bags Autoritativos (Anti-StateBag Tamper)
---------------------------------------------------------------------
-- Si un cliente intenta modificar directamente statebags del servidor (dinero, trabajo, vida)
local ProtectedBags = {
    ['luxury:data'] = true,
    ['isLoggedIn'] = true,
    ['gang'] = true,
    ['citizenid'] = true
}

for bagKey, _ in pairs(ProtectedBags) do
    AddStateBagChangeHandler(bagKey, nil, function(bagName, key, value, source, replicated)
        -- Si la modificación proviene de un cliente (source > 0)
        if source and source > 0 then
            Security.BanPlayer(source, ('Modificación ilegal de State Bag de servidor protegido (%s)'):format(key))
        end
    end)
end

---------------------------------------------------------------------
-- 4) Rate Limiting (Anti-Spam / Anti-Flood de Eventos)
---------------------------------------------------------------------
function Security.CheckRateLimit(src, maxPerSecond)
    maxPerSecond = maxPerSecond or 25
    local data = EventRateLimits[src]
    if not data then return true end

    local now = os.time()
    if now == data.lastReset then
        data.count = data.count + 1
        if data.count > maxPerSecond then
            Security.BanPlayer(src, 'Event Flooding / Ataque masivo de inyección de red')
            return false
        end
    else
        data.count = 1
        data.lastReset = now
    end
    return true
end

---------------------------------------------------------------------
-- 5) Sistema de Baneo Multi-Token y Hardware (HWID Ban)
---------------------------------------------------------------------
function Security.BanPlayer(src, reason, durationHours)
    local player = Core.Players[src]
    local name = player and player.name or GetPlayerName(src) or 'Inyector'
    local license = player and player.license or 'Desconocido'
    local ids, ip = getAllIdentifiers(src)
    local hwidTokens = getHardwareTokens(src)

    local expireTimestamp = (durationHours and durationHours > 0) and (os.time() + (durationHours * 3600)) or 0
    local expireStr = (durationHours and durationHours > 0) and ('%d horas'):format(durationHours) or 'Permanente'

    MySQL.insert([[
        INSERT INTO luxury_bans (license, name, reason, author, expire, identifiers, tokens, ip) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        license,
        name,
        reason,
        'Luxury Sentinel (Automático)',
        expireTimestamp,
        json.encode(ids),
        json.encode(hwidTokens),
        ip
    })

    MySQL.insert('INSERT INTO luxury_logs (type, identifier, action) VALUES (?, ?, ?)', {
        'security_ban', license, ('Baneado HWID por: %s (IP: %s)'):format(reason, tostring(ip))
    })

    -- Registro en Discord
    if Logger and Logger.LogBan then
        Logger.LogBan(name, license, reason, 'Luxury Sentinel', expireStr, ip)
    end

    print(('^1[LUXURY-SECURITY] SANCIONADO AUTOMÁTICAMENTE: %s (ID: %d | HWID/IP: %s) -> %s^7'):format(name, src, tostring(ip), reason))
    DropPlayer(src, ('\n🛡️ [Luxury Sentinel] Conexión denegada por seguridad.\nMotivo: %s'):format(reason))
end

---------------------------------------------------------------------
-- 6) Verificación de Baneo y Detección de Ban Evasion (HWID Check)
---------------------------------------------------------------------
function Security.CheckBans(src, deferrals)
    local playerIdentifiers, playerIp = getAllIdentifiers(src)
    local playerTokens = getHardwareTokens(src)

    local bans = MySQL.query.await('SELECT * FROM luxury_bans ORDER BY id DESC', {})
    local currentTime = os.time()

    for _, ban in ipairs(bans) do
        if ban.expire > 0 and ban.expire <= currentTime then
            MySQL.query('DELETE FROM luxury_bans WHERE id = ?', { ban.id })
        else
            local isMatch = false
            local matchReason = ''

            -- A) Comparar Licencia
            for _, id in ipairs(playerIdentifiers) do
                if id == ban.license then
                    isMatch = true
                    matchReason = 'Licencia Rockstar sancionada'
                    break
                end
            end

            -- B) Comparar Otros Identificadores (Discord, Steam, IP)
            if not isMatch and ban.identifiers then
                local bannedIds = json.decode(ban.identifiers) or {}
                for _, pId in ipairs(playerIdentifiers) do
                    for _, bId in ipairs(bannedIds) do
                        if pId == bId then
                            isMatch = true
                            matchReason = 'Identificador secundario vinculado a sanción previa'
                            break
                        end
                    end
                    if isMatch then break end
                end
            end

            -- C) Comparar Tokens de Hardware (HWID Ban Evasion)
            if not isMatch and ban.tokens then
                local bannedTokens = json.decode(ban.tokens) or {}
                for _, pToken in ipairs(playerTokens) do
                    for _, bToken in ipairs(bannedTokens) do
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
                deferrals.done(('\n⛔ ACCESO DENEGADO (Sanción Activa)\nMotivo: %s\nTipo: %s\nExpira: %s'):format(ban.reason, matchReason, expireMsg))
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
    if not src or src == 0 then return end

    local player = Core.Players[src]
    local isAdmin = player and player:hasGroup('mod')

    if not isAdmin then
        if BlacklistedExplosions[ev.explosionType] then
            CancelEvent()
            Security.BanPlayer(src, ('Intento de explosión ilegal prohibida (Tipo %d)'):format(ev.explosionType))
            return
        end

        local now = os.time()
        local record = PlayerExplosionCounts[src] or { count = 0, last = now }
        if now - record.last < 2 then
            record.count = record.count + 1
            if record.count > 2 then
                CancelEvent()
                Security.BanPlayer(src, 'Spam masivo de explosiones (Mass Explosion Exploit)')
                return
            end
        else
            record.count = 1
            record.last = now
        end
        PlayerExplosionCounts[src] = record
    end
end)

local BlacklistedVehicleModels = {
    [`rhino`] = true, [`hydra`] = true, [`lazer`] = true, [`oppressor`] = true, [`oppressor2`] = true,
    [`khanjali`] = true, [`apc`] = true, [`cargoplane`] = true, [`cerberus`] = true, [`ruiner2`] = true,
    [`stromberg`] = true, [`deluxo`] = true
}

AddEventHandler('entityCreating', function(entity)
    if not DoesEntityExist(entity) then return end
    local model = GetEntityModel(entity)
    local entityType = GetEntityType(entity)

    local owner = NetworkGetEntityOwner(entity)
    if owner and owner > 0 then
        local player = Core.Players[owner]
        local isAdmin = player and player:hasGroup('mod')

        if not isAdmin then
            if entityType == 2 and BlacklistedVehicleModels[model] then
                CancelEvent()
                Security.BanPlayer(owner, ('Spawneo no autorizado de vehículo militar prohibido (Hash: %s)'):format(tostring(model)))
                return
            end
        end
    end
end)

AddEventHandler('giveWeaponEvent', function(sender, ev)
    local src = tonumber(sender)
    if not src or src == 0 then return end

    local player = Core.Players[src]
    local isAdmin = player and player:hasGroup('admin')

    if not isAdmin then
        CancelEvent()
        Security.BanPlayer(src, 'Intento de entrega remota de armas por evento de red (giveWeaponEvent injection)')
    end
end)

AddEventHandler('removeWeaponEvent', function(sender, ev)
    local src = tonumber(sender)
    if src and src > 0 then
        local player = Core.Players[src]
        if not (player and player:hasGroup('admin')) then
            CancelEvent()
        end
    end
end)

AddEventHandler('clearPedTasksEvent', function(sender, ev)
    local src = tonumber(sender)
    if src and src > 0 then
        local player = Core.Players[src]
        if not (player and player:hasGroup('admin')) and ev.immediately then
            CancelEvent()
        end
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
        Security.BanPlayer(src, ('Inyección de evento trampa detectada (Honeypot: %s)'):format(eventName))
    end)
end

RegisterNetEvent('luxury:security:flagPlayer', function(reason)
    local src = source
    local player = Core.Players[src]
    if player and not player:hasGroup('mod') then
        if Logger and Logger.LogAnticheat then
            Logger.LogAnticheat(src, tostring(reason))
        end
        Security.BanPlayer(src, tostring(reason))
    end
end)

---------------------------------------------------------------------
-- 9) Monitor de Latido (Heartbeat)
---------------------------------------------------------------------
RegisterNetEvent('luxury:security:heartbeatResponse', function(challenge, responseHash)
    local src = source
    PlayerHeartbeats[src] = os.time()
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for src, _ in pairs(Core.Players) do
            local lastHeartbeat = PlayerHeartbeats[src] or now
            if (now - lastHeartbeat) > 75 then
                print(('^1[LUXURY-SECURITY] Desconexión por fallo de latido / Script detenido (ID: %d)^7'):format(src))
                DropPlayer(src, '🛡️ [Luxury Sentinel] Tiempo de sincronización de seguridad agotado (Script Tamper Detected).')
                PlayerHeartbeats[src] = nil
            else
                local challenge = math.random(100000, 999999)
                TriggerClientEvent('luxury:security:heartbeatChallenge', src, challenge)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    PlayerTokens[src] = nil
    PlayerHeartbeats[src] = nil
    EventRateLimits[src] = nil
    PlayerExplosionCounts[src] = nil
    PlayerPositions[src] = nil
end)

exports('ValidateToken', Security.ValidateToken)
exports('ValidateCoords', Security.ValidateCoords)
exports('CheckRateLimit', Security.CheckRateLimit)
exports('BanPlayer', Security.BanPlayer)
exports('CheckBans', Security.CheckBans)
