-- luxury_multicharacter: Lógica de Cliente y Cámara 3D
-- Compatible con Cfx.re Asset Escrow y Arquitectura Proxy Luxury Framework

local cam = nil
local previewPed = nil

--- Configuración de la Cámara Cinemática 3D
local function setupCamera()
    local cfg = Config.PreviewLocation
    if not DoesCamExist(cam) then
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end
    SetCamCoord(cam, cfg.camCoords.x, cfg.camCoords.y, cfg.camCoords.z)
    SetCamRot(cam, cfg.camRot.x, cfg.camRot.y, cfg.camRot.z, 2)
    SetCamFov(cam, cfg.camFov or 38.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
end

--- Limpieza y destrucción de la Cámara y Ped de previsualización
local function destroyCamera()
    if DoesCamExist(cam) then
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end
    RenderScriptCams(false, true, 800, true, true)

    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end
end

--- Inicialización al entrar al servidor
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    TriggerServerEvent('luxury_multicharacter:server:init')
    TriggerServerEvent('luxury_multicharacter:server:requestCharacters')
end)

--- Recibir lista de personajes y abrir la interfaz React
RegisterNetEvent('luxury_multicharacter:client:setupUI', function(characters, maxSlots)
    DoScreenFadeOut(0)
    Wait(200)

    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)

    local pCoords = Config.PreviewLocation.pedCoords
    SetEntityCoords(ped, pCoords.x, pCoords.y, pCoords.z, false, false, false, false)
    SetEntityHeading(ped, pCoords.w)

    setupCamera()

    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
    SendNUIMessage({
        action = 'OPEN_MULTICHAR',
        payload = {
            characters = characters or {},
            maxSlots = maxSlots or Config.MaxCharacters,
            spawns = Config.DefaultSpawns
        }
    })

    Wait(500)
    DoScreenFadeIn(600)
end)

--- Notificaciones desde el servidor
RegisterNetEvent('luxury_multicharacter:client:notify', function(type, message)
    SendNUIMessage({
        action = 'SHOW_NOTIFICATION',
        payload = { type = type, message = message }
    })
end)

--- Spawn del jugador en el mapa tras elegir personaje
RegisterNetEvent('luxury_multicharacter:client:spawnPlayer', function(coords, isNew)
    DoScreenFadeOut(500)
    Wait(600)

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_MULTICHAR' })

    destroyCamera()

    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)

    Wait(500)
    DoScreenFadeIn(800)

    if isNew then
        TriggerEvent('luxury_core:client:newCharacterCreated')
        TriggerEvent('esx_skin:openSaveableMenu')
    end
    TriggerEvent('esx:loadingScreenFinished')
    TriggerServerEvent('esx:onPlayerSpawn')
end)

---------------------------------------------------------------------
-- NUI Callbacks (Manejadores de Eventos React)
---------------------------------------------------------------------

RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('luxury_multicharacter:server:selectCharacter', data.citizenid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('luxury_multicharacter:server:createCharacter', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('luxury_multicharacter:server:deleteCharacter', data.citizenid)
    cb({ status = 'ok' })
end)
