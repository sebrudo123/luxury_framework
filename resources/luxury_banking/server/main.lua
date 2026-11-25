-- luxury_banking: Lógica de Servidor - okokBanking Replica
-- Compatible con TODAS las versiones de ESX y Luxury Framework

local ESX = nil
local bankCooldowns = {}

local function sanitizeBankAmount(val)
    if type(val) ~= 'number' and type(val) ~= 'string' then return nil end
    local num = tonumber(val)
    if not num or num ~= num or num <= 0 or num == math.huge or num == -math.huge or num > 2147483647 then
        return nil
    end
    return math.floor(num)
end

local function checkBankCooldown(src)
    local now = GetGameTimer()
    if bankCooldowns[src] and (now - bankCooldowns[src]) < 400 then
        return false
    end
    bankCooldowns[src] = now
    return true
end

-- Obtención segura de ESX (Compatible con v1.1, v1.2, v1-final y Legacy)
local function getESX()
    local esxObj = nil
    TriggerEvent('esx:getSharedObject', function(obj)
        esxObj = obj
    end)
    if esxObj then return esxObj end

    pcall(function()
        if exports['es_extended'] then
            esxObj = exports['es_extended']:getSharedObject()
        end
    end)
    if esxObj then return esxObj end

    pcall(function()
        if exports['luxury_core'] then
            esxObj = exports['luxury_core']:GetESX()
        end
    end)
    return esxObj
end

-- Inicialización de ESX
CreateThread(function()
    while ESX == nil do
        ESX = getESX()
        if not ESX then
            Wait(250)
        end
    end
end)

--- Inicialización de Base de Datos Automática
CreateThread(function()
    while not MySQL do Wait(100) end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_banking_transactions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(60) NOT NULL,
            `type` VARCHAR(30) NOT NULL,
            `amount` INT NOT NULL,
            `title` VARCHAR(150) NOT NULL,
            `sender` VARCHAR(100) NOT NULL,
            `recipient` VARCHAR(100) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_banking_citizenid` (`citizenid`),
            INDEX `idx_banking_type` (`type`),
            INDEX `idx_banking_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print('^2[luxury_banking]^7 Esquema SQL verificado e inicializado correctamente (okokBanking Replica).')
end)

--- Función Auxiliar: Obtener Datos Bancarios del Jugador
local function getPlayerBankPayload(src, isAtm)
    if not ESX then return nil end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end

    local identifier = xPlayer.identifier or (xPlayer.citizenid or tostring(src))
    local playerName = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or 'Ciudadano'
    local bankMoney = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0
    local cashMoney = xPlayer.getMoney() or 0

    -- Sociedad (Jefe / Boss de esx_society / esx_addonaccount)
    local societyData = nil
    local isBoss = false
    if xPlayer.job then
        if xPlayer.job.grade_name == 'boss' or xPlayer.job.isBoss then
            isBoss = true
        end
    end

    if isBoss and xPlayer.job then
        local socName = xPlayer.job.name
        local socBalance = 0

        -- Soporte esx_addonaccount
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. socName, function(account)
            if account then
                p:resolve(account.money)
            else
                p:resolve(0)
            end
        end)

        -- Timeout fallback si esx_addonaccount no responde de inmediato
        SetTimeout(200, function()
            if not p.is_resolved then p:resolve(0) end
        end)

        socBalance = Citizen.Await(p) or 0
        societyData = {
            name = socName,
            label = xPlayer.job.label or socName,
            balance = socBalance
        }
    end

    -- Obtener últimas 20 transacciones
    local transactions = MySQL.query.await([[
        SELECT id, type, amount, title, sender, recipient, DATE_FORMAT(created_at, '%d/%m %H:%i') AS date
        FROM luxury_banking_transactions
        WHERE citizenid = ?
        ORDER BY id DESC
        LIMIT 20
    ]], { identifier }) or {}

    -- Generar IBAN estilo okokBanking (OKOK-XXXX)
    local cleanId = identifier:gsub('license:', ''):sub(1, 4):upper()
    local userIban = (Config.IBANPrefix or 'OKOK-') .. (cleanId ~= '' and cleanId or ('%04d'):format(src))

    return {
        name = playerName,
        iban = userIban,
        bank = bankMoney,
        cash = cashMoney,
        isAtm = isAtm or false,
        society = societyData,
        transactions = transactions
    }
end

--- Solicitud de Apertura de Banco
RegisterNetEvent('luxury_banking:server:requestData', function(isAtm)
    local src = source
    local data = getPlayerBankPayload(src, isAtm)
    if data then
        TriggerClientEvent('luxury_banking:client:openBank', src, data)
    end
end)

--- Retiro de Dinero
RegisterNetEvent('luxury_banking:server:withdraw', function(amount, isAtm)
    local src = source
    if not ESX or not checkBankCooldown(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    amount = sanitizeBankAmount(amount)
    if not xPlayer or not amount then return end

    local identifier = xPlayer.identifier or xPlayer.citizenid or tostring(src)
    local bankMoney = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0

    local fee = 0
    if isAtm and Config.ATMFeePercentage and Config.ATMFeePercentage > 0 then
        fee = math.floor(amount * (Config.ATMFeePercentage / 100))
    end
    local totalCost = amount + fee

    if bankMoney < totalCost then
        TriggerClientEvent('luxury_banking:client:openBank', src, {
            error = true,
            message = 'Fondos insuficientes en el banco.'
        })
        xPlayer.showNotification('~r~Fondos insuficientes en el banco.')
        return
    end

    xPlayer.removeAccountMoney('bank', totalCost)
    xPlayer.addMoney(amount)

    local title = isAtm and ('Retiro en Cajero ATM (Comisión: $' .. fee .. ')') or 'Retiro en Ventanilla'
    MySQL.insert([[
        INSERT INTO luxury_banking_transactions (citizenid, type, amount, title, sender, recipient)
        VALUES (?, 'withdraw', ?, ?, ?, 'Efectivo')
    ]], { identifier, amount, title, xPlayer.name or 'Yo' })

    xPlayer.showNotification('~g~Has retirado $' .. amount .. ' de tu cuenta.')

    local updated = getPlayerBankPayload(src, isAtm)
    if updated then
        TriggerClientEvent('luxury_banking:client:updateData', src, updated)
    end
end)

--- Depósito de Dinero
RegisterNetEvent('luxury_banking:server:deposit', function(amount)
    local src = source
    if not ESX or not checkBankCooldown(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    amount = sanitizeBankAmount(amount)
    if not xPlayer or not amount then return end

    local identifier = xPlayer.identifier or xPlayer.citizenid or tostring(src)
    local cashMoney = xPlayer.getMoney() or 0

    if cashMoney < amount then
        xPlayer.showNotification('~r~No tienes suficiente dinero en efectivo.')
        return
    end

    xPlayer.removeMoney(amount)
    xPlayer.addAccountMoney('bank', amount)

    MySQL.insert([[
        INSERT INTO luxury_banking_transactions (citizenid, type, amount, title, sender, recipient)
        VALUES (?, 'deposit', ?, 'Depósito en Efectivo', 'Efectivo', ?)
    ]], { identifier, amount, xPlayer.name or 'Yo' })

    xPlayer.showNotification('~g~Has depositado $' .. amount .. ' en tu cuenta.')

    local updated = getPlayerBankPayload(src, false)
    if updated then
        TriggerClientEvent('luxury_banking:client:updateData', src, updated)
    end
end)

--- Transferencia de Dinero
RegisterNetEvent('luxury_banking:server:transfer', function(targetInput, amount, description)
    local src = source
    if not ESX or not checkBankCooldown(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    amount = sanitizeBankAmount(amount)
    if not xPlayer or not targetInput or not amount then return end

    local senderIdentifier = xPlayer.identifier or xPlayer.citizenid or tostring(src)
    local bankMoney = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0

    if bankMoney < amount then
        xPlayer.showNotification('~r~Saldo bancario insuficiente para transferir.')
        return
    end

    local targetSrc = tonumber(targetInput)
    local xTarget = targetSrc and ESX.GetPlayerFromId(targetSrc) or nil

    if not xTarget then
        xPlayer.showNotification('~r~El destinatario no se encuentra conectado.')
        return
    end

    if xTarget.source == xPlayer.source then
        xPlayer.showNotification('~r~No puedes transferirte dinero a ti mismo.')
        return
    end

    local targetIdentifier = xTarget.identifier or xTarget.citizenid or tostring(xTarget.source)

    xPlayer.removeAccountMoney('bank', amount)
    xTarget.addAccountMoney('bank', amount)

    local note = (description and description ~= '') and (' - ' .. description) or ''

    -- Registro para emisor
    MySQL.insert([[
        INSERT INTO luxury_banking_transactions (citizenid, type, amount, title, sender, recipient)
        VALUES (?, 'transfer_out', ?, ?, ?, ?)
    ]], { senderIdentifier, amount, 'Transferencia a ' .. (xTarget.name or 'Ciudadano') .. note, xPlayer.name or 'Yo', xTarget.name or 'Destinatario' })

    -- Registro para receptor
    MySQL.insert([[
        INSERT INTO luxury_banking_transactions (citizenid, type, amount, title, sender, recipient)
        VALUES (?, 'transfer_in', ?, ?, ?, ?)
    ]], { targetIdentifier, amount, 'Transferencia de ' .. (xPlayer.name or 'Ciudadano') .. note, xPlayer.name or 'Emisor', xTarget.name or 'Yo' })

    xPlayer.showNotification('~g~Transferiste $' .. amount .. ' a ' .. (xTarget.name or 'Ciudadano'))
    xTarget.showNotification('~g~Recibiste una transferencia de $' .. amount .. ' de ' .. (xPlayer.name or 'Ciudadano'))

    local updatedSender = getPlayerBankPayload(src, false)
    if updatedSender then
        TriggerClientEvent('luxury_banking:client:updateData', src, updatedSender)
    end

    local updatedTarget = getPlayerBankPayload(xTarget.source, false)
    if updatedTarget then
        TriggerClientEvent('luxury_banking:client:updateData', xTarget.source, updatedTarget)
    end
end)

--- Acciones de Cuenta de Sociedad (Jefe de Empresa)
RegisterNetEvent('luxury_banking:server:societyAction', function(actionType, amount)
    local src = source
    if not ESX or not checkBankCooldown(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    amount = sanitizeBankAmount(amount)
    if not xPlayer or not xPlayer.job or not amount then return end

    if xPlayer.job.grade_name ~= 'boss' and not xPlayer.job.isBoss then
        xPlayer.showNotification('~r~No tienes permisos de jefe para esta cuenta de empresa.')
        return
    end

    local socName = 'society_' .. xPlayer.job.name

    TriggerEvent('esx_addonaccount:getSharedAccount', socName, function(account)
        if not account then
            xPlayer.showNotification('~r~No se encontró la cuenta de sociedad especificada.')
            return
        end

        if actionType == 'withdraw' then
            if account.money < amount then
                xPlayer.showNotification('~r~La empresa no dispone de fondos suficientes.')
                return
            end
            account.removeMoney(amount)
            xPlayer.addMoney(amount)
            xPlayer.showNotification('~g~Retiraste $' .. amount .. ' de la cuenta de sociedad.')
        elseif actionType == 'deposit' then
            local cash = xPlayer.getMoney() or 0
            if cash < amount then
                xPlayer.showNotification('~r~No tienes suficiente efectivo en mano.')
                return
            end
            xPlayer.removeMoney(amount)
            account.addMoney(amount)
            xPlayer.showNotification('~g~Depositaste $' .. amount .. ' a la cuenta de sociedad.')
        end

        local updated = getPlayerBankPayload(src, false)
        if updated then
            TriggerClientEvent('luxury_banking:client:updateData', src, updated)
        end
    end)
end)
