-- luxury_banking: Lógica de Cliente - okokBanking Replica
-- Compatible con TODAS las versiones de ESX y Luxury Core

local ESX = nil
local isBankOpen = false
local currentIsAtm = false

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

--- Creación de Blips de Banco en el Mapa
CreateThread(function()
    for _, bank in ipairs(Config.Banks or {}) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, 108)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.75)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(bank.name or "Banco Fleeca")
        EndTextCommandSetBlipName(blip)
    end
end)

--- Mostrar Notificación de Ayuda nativa de ESX
local function showHelpNotification(text)
    if ESX and ESX.ShowHelpNotification then
        ESX.ShowHelpNotification(text)
    else
        BeginTextCommandDisplayHelp("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayHelp(0, false, true, -1)
    end
end

--- Detectar ATM cercano
local function getNearbyATM()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, prop in ipairs(Config.ATMProps or {}) do
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.3, prop, false, false, false)
        if obj ~= 0 and DoesEntityExist(obj) then
            return obj, GetEntityCoords(obj)
        end
    end
    return nil, nil
end

--- Hilo de Detección de Interacción para Bancos y Cajeros
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if not isBankOpen and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, true) then
            local pCoords = GetEntityCoords(ped)
            local nearPoint = false

            -- 1. Sucursales de Banco
            for _, bank in ipairs(Config.Banks or {}) do
                local dist = #(pCoords - bank.coords)
                if dist < 4.0 then
                    sleep = 0
                    nearPoint = true
                    if dist < 1.8 then
                        showHelpNotification("Presiona ~INPUT_CONTEXT~ para acceder a ~g~okokBanking~w~")
                        if IsControlJustPressed(0, 38) then -- Tecla E
                            currentIsAtm = false
                            PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                            TriggerServerEvent('luxury_banking:server:requestData', false)
                        end
                    end
                    break
                end
            end

            -- 2. Cajeros Automáticos (ATMs)
            if not nearPoint then
                local atmObj, _ = getNearbyATM()
                if atmObj then
                    sleep = 0
                    showHelpNotification("Presiona ~INPUT_CONTEXT~ para usar el ~g~Cajero Automático (ATM)~w~")
                    if IsControlJustPressed(0, 38) then -- Tecla E
                        currentIsAtm = true
                        PlaySoundFrontend(-1, "PIN_BUTTON", "ATM_SOUNDS", true)
                        TriggerServerEvent('luxury_banking:server:requestData', true)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

--- Abrir Interfaz Bancaria NUI
RegisterNetEvent('luxury_banking:client:openBank', function(data)
    isBankOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OPEN_BANK',
        payload = data
    })
end)

--- Actualizar Datos en NUI
RegisterNetEvent('luxury_banking:client:updateData', function(data)
    SendNUIMessage({
        action = 'UPDATE_DATA',
        payload = data
    })
end)

--- NUI Callback: Retirar Dinero
RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('luxury_banking:server:withdraw', tonumber(data.amount) or 0, currentIsAtm)
    cb('ok')
end)

--- NUI Callback: Depositar Dinero
RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('luxury_banking:server:deposit', tonumber(data.amount) or 0)
    cb('ok')
end)

--- NUI Callback: Transferir Dinero
RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('luxury_banking:server:transfer', data.target, tonumber(data.amount) or 0, data.description)
    cb('ok')
end)

--- NUI Callback: Retirar de Sociedad
RegisterNUICallback('societyWithdraw', function(data, cb)
    TriggerServerEvent('luxury_banking:server:societyAction', 'withdraw', tonumber(data.amount) or 0)
    cb('ok')
end)

--- NUI Callback: Depositar a Sociedad
RegisterNUICallback('societyDeposit', function(data, cb)
    TriggerServerEvent('luxury_banking:server:societyAction', 'deposit', tonumber(data.amount) or 0)
    cb('ok')
end)

--- NUI Callback: Cerrar Banco
RegisterNUICallback('close', function(_, cb)
    isBankOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
