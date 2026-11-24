-- luxury_core: Funciones Globales del Servidor (Server Functions)
Core = Core or {}
Core.Players = Core.Players or {}
local isPlayerLoading = {}

--- Obtiene la licencia Rockstar principal de un jugador
-- @param src number
-- @return string|nil
function Core.GetLicense(src)
    local identifiers = GetPlayerIdentifiers(src)
    local fallbackLicense = nil

    for _, id in ipairs(identifiers) do
        if id:sub(1, 9) == 'license2:' then
            return id
        elseif id:sub(1, 8) == 'license:' then
            fallbackLicense = id
        end
    end

    return fallbackLicense
end

--- Obtiene el objeto Player por su Source
-- @param src number
-- @return table|nil
function Core.GetPlayer(src)
    return Core.Players[tonumber(src)]
end

--- Retorna todos los jugadores conectados indexados por Source
-- @return table
function Core.GetPlayers()
    return Core.Players
end

--- Busca un jugador conectado por su Citizen ID único
-- @param cid string: CitizenID (ej: 'LUX18923')
-- @return table|nil
function Core.GetPlayerByCitizenId(cid)
    if not cid then return nil end
    for _, player in pairs(Core.Players) do
        if player.citizenid == cid then
            return player
        end
    end
    return nil
end

--- Busca un jugador conectado por su número de teléfono
-- @param phone string
-- @return table|nil
function Core.GetPlayerByPhone(phone)
    if not phone then return nil end
    for _, player in pairs(Core.Players) do
        if player.charinfo and player.charinfo.phone == phone then
            return player
        end
    end
    return nil
end

--- Obtiene ambos formatos posibles de licencia Rockstar (license y license2)
local function getAllLicenseVariants(src)
    local lic1, lic2 = nil, nil
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then
            lic1 = id
        elseif id:sub(1, 9) == 'license2:' then
            lic2 = id
        end
    end
    return lic1, lic2
end

--- Descarga de forma limpia la sesión de un personaje (Multi-Character / Logout)
-- @param src number
-- @param returnToMultichar boolean|nil
function Core.UnloadPlayer(src, returnToMultichar)
    src = tonumber(src)
    local player = src and Core.Players[src]
    if not player then return false end

    local ped = GetPlayerPed(src)
    if ped and DoesEntityExist(ped) then
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        player:setCoords({ x = pos.x, y = pos.y, z = pos.z, heading = heading })
    end

    player:save(false)
    Core.Players[src] = nil

    if type(Player) == 'function' then
        local pObj = Player(src)
        local playerState = pObj and pObj.state
        if playerState then
            playerState:set('isLoggedIn', false, true)
            playerState:set('citizenid', nil, true)
            playerState:set('isDead', false, true)
        end
    end

    TriggerEvent('luxury:server:playerUnloaded', src, player.citizenid)
    TriggerEvent('esx:playerDropped', src)
    TriggerEvent('QBCore:Server:OnPlayerUnload', src)
    TriggerClientEvent('QBCore:Client:OnPlayerUnload', src)

    if returnToMultichar and GetResourceState('luxury_multicharacter') == 'started' then
        SetPlayerRoutingBucket(src, src)
        TriggerEvent('luxury_multicharacter:server:requestCharacters', src)
    end

    return true
end

--- Carga los datos de un jugador desde la base de datos y crea su instancia Player
-- @param src number
-- @param citizenid string|nil: CitizenID específico para Multi-Character
function Core.LoadPlayer(src, citizenid)
    src = tonumber(src)
    if not src or isPlayerLoading[src] then return end
    if Core.Players[src] then
        if citizenid and Core.Players[src].citizenid ~= citizenid then
            Core.UnloadPlayer(src, false)
        else
            return
        end
    end
    isPlayerLoading[src] = true

    local license = Core.GetLicense(src)
    if not license then
        isPlayerLoading[src] = nil
        DropPlayer(src, 'No se pudo obtener tu identificador de Rockstar Games (license).')
        return
    end

    local lic1, lic2 = getAllLicenseVariants(src)
    local row = nil

    if citizenid then
        row = MySQL.single.await('SELECT * FROM luxury_players WHERE citizenid = ? AND (license = ? OR license = ? OR license = ?)', {
            citizenid, license, lic1 or license, lic2 or license
        })
    else
        row = MySQL.single.await('SELECT * FROM luxury_players WHERE license = ? OR license = ? OR license = ? ORDER BY id ASC LIMIT 1', {
            license, lic1 or license, lic2 or license
        })
    end

    if not row then
        local charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
        local cid = citizenid or 'LUX'
        if not citizenid then
            for _ = 1, 5 do
                local rand = math.random(1, #charset)
                cid = cid .. charset:sub(rand, rand)
            end
        end
        local defaultPosJson = json.encode(Config.DefaultSpawn)
        local defaultNeeds = json.encode({ hunger = 100.0, thirst = 100.0 })
        local defaultMeta = json.encode({ isdead = false, inlaststand = false, injail = 0, armor = 0, stress = 0, handcuffed = false, callsign = 'NO-CALLSIGN' })
        local defaultCharinfo = json.encode({
            firstname = 'Ciudadano',
            lastname = tostring(src),
            birthdate = '1998-01-01',
            gender = 0,
            nationality = 'Los Santos',
            phone = ('555-%04d'):format(math.random(1000, 9999)),
            licences = { driver = true, weapon = false, hunting = false, pilot = false }
        })

        MySQL.insert.await([[
            INSERT INTO luxury_players 
            (license, citizenid, name, cash, bank, black_money, crypto, job, job_grade, gang, gang_grade, position, `group`, needs, metadata, charinfo) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            license, cid, GetPlayerName(src),
            Config.StartCash or 500, Config.StartBank or 2500, Config.StartBlackMoney or 0, Config.StartCrypto or 0,
            Config.DefaultJob.name, Config.DefaultJob.grade,
            Config.DefaultGang.name, Config.DefaultGang.grade,
            defaultPosJson, Config.Admins[license] or 'user',
            defaultNeeds, defaultMeta, defaultCharinfo
        })
        row = MySQL.single.await('SELECT * FROM luxury_players WHERE citizenid = ?', { cid })
    end

    -- Comprobar si el cliente se desconectó mientras respondía la base de datos
    if not GetPlayerPing(src) or GetPlayerPing(src) <= 0 then
        isPlayerLoading[src] = nil
        return
    end

    local player = LuxuryPlayer.new(src, row.license or license, row)
    Core.Players[src] = player

    -- State Bags de sesión
    if type(Player) == 'function' then
        local pObj = Player(src)
        local playerState = pObj and pObj.state
        if playerState then
            playerState:set('isLoggedIn', true, true)
            playerState:set('citizenid', player.citizenid, true)
            playerState:set('instance', 0, true)
        end
    end

    -- Sincronización con cliente
    player:sync()

    -- Enviar spawn con armadura persistente si corresponde
    local savedArmor = (Config.ArmorPersistence ~= false and player.metadata and player.metadata.armor) or 0
    TriggerClientEvent('luxury:client:spawnPlayer', src, player:getCoords(), savedArmor)

    -- Evento nativo Luxury
    TriggerEvent('luxury:server:playerLoaded', src, player)

    -- Eventos de compatibilidad con ESX, QBCore y Qbox
    if ESX and ESX.GetPlayerFromId then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            TriggerEvent('esx:playerLoaded', src, xPlayer)
            TriggerClientEvent('esx:playerLoaded', src, xPlayer, true)
        end
    end

    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        local qPlayer = QBCore.Functions.GetPlayer(src)
        if qPlayer then
            TriggerEvent('QBCore:Server:OnPlayerLoaded', qPlayer)
            TriggerClientEvent('QBCore:Client:OnPlayerLoaded', src)
            TriggerClientEvent('qbx_core:client:playerLoaded', src)
        end
    end

    if Logger and Logger.LogConnection then
        Logger.LogConnection(player.name, player.license, 'Conexión', ('Personaje %s cargado (ID: %d)'):format(player.citizenid, src))
    end

    print(('^2[luxury_core]^7 Jugador cargado: %s (ID: %d | CID: ^3%s^7 | Rango: %s)'):format(player.name, src, player.citizenid, player.group))
    isPlayerLoading[src] = nil
end

-- Puente directo para recursos de selección Multi-Character
AddEventHandler('luxury_core:server:playerLoaded', function(src, citizenid)
    if src and not Core.Players[tonumber(src)] then
        Core.LoadPlayer(src, citizenid)
    elseif src and citizenid then
        Core.LoadPlayer(src, citizenid)
    end
end)

-- Exports
exports('GetPlayer', Core.GetPlayer)
exports('GetPlayers', Core.GetPlayers)
exports('GetPlayerByCitizenId', Core.GetPlayerByCitizenId)
exports('GetPlayerByPhone', Core.GetPlayerByPhone)
exports('GetLicense', Core.GetLicense)
exports('LoadPlayer', Core.LoadPlayer)
exports('UnloadPlayer', Core.UnloadPlayer)
