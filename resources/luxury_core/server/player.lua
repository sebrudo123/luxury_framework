-- luxury_core: Clase Jugador (Player Class con Metatable estilo Qbox)
LuxuryPlayer = {}
LuxuryPlayer.__index = LuxuryPlayer
Core = Core or {}
Core.Player = LuxuryPlayer

--- Generador de Citizen ID único (ej: LUX18923)
local function generateCitizenId()
    local charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    local result = 'LUX'
    for _ = 1, 5 do
        local rand = math.random(1, #charset)
        result = result .. charset:sub(rand, rand)
    end
    return result
end

local VALID_ACCOUNTS = {
    cash = true,
    bank = true,
    black_money = true,
    crypto = true
}

--- Sanitización interna estricta contra NaN, Infinitos o desbordamientos
local function sanitizeAmount(amount, allowZero)
    if type(amount) ~= 'number' and type(amount) ~= 'string' then return nil end
    local num = tonumber(amount)
    local minVal = allowZero and 0 or 1
    if not num or num ~= num or num < minVal or num == math.huge or num == -math.huge or num > 2147483647 then
        return nil
    end
    return math.floor(num)
end

local function normalizeAccount(account)
    if account == 'money' then return 'cash' end
    return account
end

--- Constructor de un nuevo objeto Jugador
-- @param src number: Source de FiveM
-- @param license string: Identificador Rockstar
-- @param row table: Datos obtenidos de la base de datos
-- @return table: Instancia de Player
function LuxuryPlayer.new(src, license, row)
    local self = setmetatable({}, LuxuryPlayer)

    self.source = src
    self.license = license
    self.citizenid = row.citizenid or generateCitizenId()
    self.name = GetPlayerName(src) or ('Desconocido (%s)'):format(src)
    self.cash = tonumber(row.cash) or 0
    self.bank = tonumber(row.bank) or 0
    self.black_money = tonumber(row.black_money) or 0
    self.crypto = tonumber(row.crypto) or 0

    -- 1) Trabajo (Legal Job con soporte onduty)
    local jobName = row.job or Config.DefaultJob.name
    local jobGrade = tonumber(row.job_grade) or Config.DefaultJob.grade
    local jobInfo = GetJobInfo(jobName, jobGrade)

    self.job = {
        name = jobName,
        grade = jobGrade,
        label = jobInfo and jobInfo.label or jobName,
        grade_label = jobInfo and jobInfo.grade_label or ('Rango %d'):format(jobGrade),
        salary = jobInfo and jobInfo.salary or 0,
        isBoss = jobInfo and jobInfo.isBoss or false,
        onduty = jobInfo and (jobInfo.defaultDuty ~= false) or true
    }

    -- 2) Banda / Facción Ilegal (Gang System independiente)
    local gangName = row.gang or Config.DefaultGang.name
    local gangGrade = tonumber(row.gang_grade) or Config.DefaultGang.grade
    local gangInfo = GetGangInfo(gangName, gangGrade)

    self.gang = {
        name = gangName,
        grade = gangGrade,
        label = gangInfo and gangInfo.label or gangName,
        grade_label = gangInfo and gangInfo.grade_label or ('Rango %d'):format(gangGrade),
        isBoss = gangInfo and gangInfo.isBoss or false
    }

    -- 3) Identidad y Licencias (Charinfo)
    local decodedCharinfo = (type(row.charinfo) == 'string' and json.decode(row.charinfo)) or row.charinfo or {}
    self.charinfo = {
        firstname = decodedCharinfo.firstname or 'Ciudadano',
        lastname = decodedCharinfo.lastname or tostring(src),
        birthdate = decodedCharinfo.birthdate or '1998-01-01',
        gender = decodedCharinfo.gender or 0,
        nationality = decodedCharinfo.nationality or 'Los Santos',
        phone = decodedCharinfo.phone or ('555-%04d'):format(math.random(1000, 9999)),
        licences = decodedCharinfo.licences or { driver = true, weapon = false, hunting = false, pilot = false }
    }

    -- 4) Necesidades (Hambre y Sed)
    local decodedNeeds = (type(row.needs) == 'string' and json.decode(row.needs)) or row.needs or {}
    self.needs = {
        hunger = tonumber(decodedNeeds.hunger) or 100.0,
        thirst = tonumber(decodedNeeds.thirst) or 100.0
    }

    -- 5) Metadata extensible persistente
    local decodedMeta = (type(row.metadata) == 'string' and json.decode(row.metadata)) or row.metadata or {}
    self.metadata = {
        isdead = decodedMeta.isdead == true,
        inlaststand = decodedMeta.inlaststand == true,
        injail = tonumber(decodedMeta.injail) or 0,
        armor = tonumber(decodedMeta.armor) or 0,
        stress = tonumber(decodedMeta.stress) or 0,
        handcuffed = decodedMeta.handcuffed == true,
        callsign = decodedMeta.callsign or 'NO-CALLSIGN'
    }
    for k, v in pairs(decodedMeta) do
        if self.metadata[k] == nil then
            self.metadata[k] = v
        end
    end

    self.coords = (type(row.position) == 'string' and json.decode(row.position)) or Config.DefaultSpawn
    self.group = row.group or Config.Admins[license] or 'user'
    self.isFrozen = false

    return self
end

---------------------------------------------------------------------
-- Métodos de Economía (cash, bank, black_money, crypto)
---------------------------------------------------------------------
function LuxuryPlayer:getMoney(account)
    local acc = normalizeAccount(account)
    if not VALID_ACCOUNTS[acc] then return 0 end
    return self[acc] or 0
end

function LuxuryPlayer:addMoney(account, amount, reason)
    local acc = normalizeAccount(account)
    local cleanAmount = sanitizeAmount(amount, false)
    if not cleanAmount or not VALID_ACCOUNTS[acc] then
        return false
    end

    self[acc] = (self[acc] or 0) + cleanAmount
    self:sync()
    if Logger and Logger.LogEconomy and cleanAmount >= 10000 then
        Logger.LogEconomy(self.source, acc, cleanAmount, 'Ingreso', reason)
    end
    return true
end

function LuxuryPlayer:removeMoney(account, amount, reason)
    local acc = normalizeAccount(account)
    local cleanAmount = sanitizeAmount(amount, false)
    if not cleanAmount or not VALID_ACCOUNTS[acc] then
        return false
    end

    if (self[acc] or 0) < cleanAmount then
        return false
    end

    self[acc] = self[acc] - cleanAmount
    self:sync()
    if Logger and Logger.LogEconomy and cleanAmount >= 10000 then
        Logger.LogEconomy(self.source, acc, cleanAmount, 'Retiro', reason)
    end
    return true
end

function LuxuryPlayer:setMoney(account, amount, reason)
    local acc = normalizeAccount(account)
    local cleanAmount = sanitizeAmount(amount, true)
    if not cleanAmount or not VALID_ACCOUNTS[acc] then
        return false
    end

    self[acc] = cleanAmount
    self:sync()
    if Logger and Logger.LogEconomy then
        Logger.LogEconomy(self.source, acc, cleanAmount, 'Ajuste Exacto', reason)
    end
    return true
end

---------------------------------------------------------------------
-- Métodos de Trabajo (Job y Duty)
---------------------------------------------------------------------
function LuxuryPlayer:setJob(name, grade)
    if not name or type(name) ~= 'string' then return false end
    grade = tonumber(grade) or 0

    local jobInfo = GetJobInfo(name, grade)
    if not jobInfo then
        print(('[^1ERROR^7] Intento de asignar trabajo no registrado: %s'):format(name))
        return false
    end

    self.job = {
        name = name,
        grade = grade,
        label = jobInfo.label,
        grade_label = jobInfo.grade_label,
        salary = jobInfo.salary,
        isBoss = jobInfo.isBoss,
        onduty = jobInfo.defaultDuty ~= false
    }

    self:sync()

    -- Compatibilidad ESX, QBCore y Qbox
    TriggerEvent('esx:setJob', self.source, self.job)
    TriggerClientEvent('esx:setJob', self.source, self.job)
    TriggerEvent('QBCore:Server:OnJobUpdate', self.source, self.job)
    TriggerClientEvent('QBCore:Client:OnJobUpdate', self.source, self.job)
    TriggerClientEvent('QBCore:Client:SetDuty', self.source, self.job.onduty)
    TriggerClientEvent('qbx_core:client:jobUpdated', self.source, self.job)

    return true
end

function LuxuryPlayer:setDuty(state)
    local newDuty = state == true
    if self.job.onduty == newDuty then return newDuty end

    self.job.onduty = newDuty
    self:sync()

    TriggerEvent('luxury:server:dutyChanged', self.source, self.job.name, newDuty)
    TriggerEvent('esx:setJob', self.source, self.job)
    TriggerClientEvent('esx:setJob', self.source, self.job)
    TriggerEvent('QBCore:Server:SetDuty', self.source, newDuty)
    TriggerClientEvent('QBCore:Client:SetDuty', self.source, newDuty)
    TriggerClientEvent('QBCore:Client:OnJobUpdate', self.source, self.job)
    TriggerClientEvent('qbx_core:client:jobUpdated', self.source, self.job)

    return newDuty
end

function LuxuryPlayer:isOnDuty()
    return self.job and self.job.onduty == true
end

function LuxuryPlayer:getJob()
    return self.job
end

---------------------------------------------------------------------
-- Métodos de Banda / Pandilla (Gang)
---------------------------------------------------------------------
function LuxuryPlayer:setGang(name, grade)
    if not name or type(name) ~= 'string' then return false end
    grade = tonumber(grade) or 0

    local gangInfo = GetGangInfo(name, grade)
    self.gang = {
        name = name,
        grade = grade,
        label = gangInfo.label,
        grade_label = gangInfo.grade_label,
        isBoss = gangInfo.isBoss
    }

    self:sync()

    -- Compatibilidad con scripts de bandas de QBCore y Qbox
    TriggerEvent('QBCore:Server:OnGangUpdate', self.source, self.gang)
    TriggerClientEvent('QBCore:Client:OnGangUpdate', self.source, self.gang)

    return true
end

function LuxuryPlayer:getGang()
    return self.gang
end

---------------------------------------------------------------------
-- Métodos de Licencias (Licenses)
---------------------------------------------------------------------
function LuxuryPlayer:hasLicense(licType)
    return self.charinfo.licences and self.charinfo.licences[licType] == true or false
end

function LuxuryPlayer:grantLicense(licType)
    if not self.charinfo.licences then self.charinfo.licences = {} end
    self.charinfo.licences[licType] = true
    self:sync()
    return true
end

function LuxuryPlayer:revokeLicense(licType)
    if not self.charinfo.licences then self.charinfo.licences = {} end
    self.charinfo.licences[licType] = false
    self:sync()
    return true
end

function LuxuryPlayer:getLicenses()
    return self.charinfo.licences or {}
end

---------------------------------------------------------------------
-- Métodos de Dimensiones / Instancias (Routing Buckets)
---------------------------------------------------------------------
function LuxuryPlayer:setBucket(bucket)
    return SetPlayerBucket(self.source, bucket)
end

function LuxuryPlayer:getBucket()
    return GetPlayerBucket(self.source)
end

---------------------------------------------------------------------
-- Métodos de Identidad y Necesidades
---------------------------------------------------------------------
function LuxuryPlayer:getCitizenId()
    return self.citizenid
end

function LuxuryPlayer:getCharInfo()
    return self.charinfo
end

function LuxuryPlayer:setCharInfo(data)
    if type(data) ~= 'table' then return end
    for k, v in pairs(data) do
        self.charinfo[k] = v
    end
    self:sync()
    return true
end

function LuxuryPlayer:getNeed(need)
    return self.needs[need] or 0
end

function LuxuryPlayer:setNeed(need, amount)
    if need ~= 'hunger' and need ~= 'thirst' then return false end
    self.needs[need] = math.max(0.0, math.min(100.0, tonumber(amount) or 0.0))
    self:sync()
    return true
end

function LuxuryPlayer:addNeed(need, amount)
    if need ~= 'hunger' and need ~= 'thirst' then return false end
    local add = tonumber(amount) or 0
    self.needs[need] = math.min(100.0, self.needs[need] + add)
    self:sync()
    return true
end

function LuxuryPlayer:removeNeed(need, amount)
    if need ~= 'hunger' and need ~= 'thirst' then return false end
    local rem = tonumber(amount) or 0
    self.needs[need] = math.max(0.0, self.needs[need] - rem)
    self:sync()
    return true
end

function LuxuryPlayer:hasGroup(group)
    local playerLevel = Config.Groups[self.group] or 0
    local targetLevel = Config.Groups[group] or 0
    return playerLevel >= targetLevel
end

---------------------------------------------------------------------
-- Métodos de Coordenadas
---------------------------------------------------------------------
function LuxuryPlayer:setCoords(coords)
    if not coords then return end
    if type(coords) == 'vector3' or type(coords) == 'vector4' then
        self.coords = { x = coords.x, y = coords.y, z = coords.z, heading = coords.w or coords.heading or 0.0 }
    elseif type(coords) == 'table' and coords.x and coords.y and coords.z then
        self.coords = { x = coords.x, y = coords.y, z = coords.z, heading = coords.heading or 0.0 }
    end
end

function LuxuryPlayer:getCoords()
    return self.coords or Config.DefaultSpawn
end

---------------------------------------------------------------------
-- Métodos de Inventario (ox_inventory Bridge)
---------------------------------------------------------------------
function LuxuryPlayer:addItem(item, count, metadata, slot)
    return Inventory.AddItem(self.source, item, count, metadata, slot)
end

function LuxuryPlayer:removeItem(item, count, metadata, slot)
    return Inventory.RemoveItem(self.source, item, count, metadata, slot)
end

function LuxuryPlayer:getItem(item, metadata)
    return Inventory.GetItem(self.source, item, metadata)
end

function LuxuryPlayer:hasItem(item, count)
    return Inventory.HasItem(self.source, item, count)
end

function LuxuryPlayer:canCarryItem(item, count)
    return Inventory.CanCarryItem(self.source, item, count)
end

function LuxuryPlayer:getInventory()
    return Inventory.GetInventory(self.source)
end

function LuxuryPlayer:clearInventory()
    return Inventory.ClearInventory(self.source)
end

---------------------------------------------------------------------
-- Métodos de Metadata Extensible
---------------------------------------------------------------------
function LuxuryPlayer:getMetadata(key)
    if not self.metadata then self.metadata = {} end
    if key == nil then return self.metadata end
    return self.metadata[key]
end

function LuxuryPlayer:setMetadata(key, value)
    if not key then return false end
    if not self.metadata then self.metadata = {} end
    self.metadata[key] = value
    self:sync()
    return true
end

---------------------------------------------------------------------
-- Sincronización y Persistencia
---------------------------------------------------------------------
function LuxuryPlayer:sync()
    local payload = {
        citizenid = self.citizenid,
        cash = self.cash,
        bank = self.bank,
        black_money = self.black_money or 0,
        crypto = self.crypto or 0,
        job = self.job,
        gang = self.gang,
        group = self.group,
        charinfo = self.charinfo,
        needs = self.needs,
        metadata = self.metadata
    }

    -- Sincronización State Bags de OneSync
    if type(Player) == 'function' then
        local pObj = Player(self.source)
        local playerState = pObj and pObj.state
        if playerState then
            playerState:set('luxury:data', payload, true)
            playerState:set('citizenid', self.citizenid, true)
            playerState:set('hunger', self.needs.hunger, true)
            playerState:set('thirst', self.needs.thirst, true)
            playerState:set('gang', self.gang, true)
            playerState:set('isDead', self.metadata and self.metadata.isdead or false, true)
        end
    end

    -- Evento cliente para compatibilidad retroactiva
    TriggerClientEvent('luxury:client:update', self.source, payload)
end

function LuxuryPlayer:save(isAsync)
    if isAsync == nil then isAsync = true end

    if Config.ArmorPersistence ~= false and self.metadata then
        local ped = GetPlayerPed(self.source)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            local ok, armor = pcall(GetPedArmour, ped)
            if ok and type(armor) == 'number' then
                self.metadata.armor = armor
            end
        end
    end

    local query = [[
        UPDATE luxury_players 
        SET name = ?, cash = ?, bank = ?, black_money = ?, crypto = ?, job = ?, job_grade = ?, gang = ?, gang_grade = ?, charinfo = ?, position = ?, `group` = ?, needs = ?, metadata = ? 
        WHERE citizenid = ? AND license = ?
    ]]
    local params = {
        self.name,
        self.cash,
        self.bank,
        self.black_money or 0,
        self.crypto or 0,
        self.job.name,
        self.job.grade,
        self.gang.name,
        self.gang.grade,
        json.encode(self.charinfo),
        json.encode(self.coords),
        self.group,
        json.encode(self.needs),
        json.encode(self.metadata or {}),
        self.citizenid,
        self.license
    }

    if isAsync then
        MySQL.update(query, params)
    else
        MySQL.update.await(query, params)
    end
end
