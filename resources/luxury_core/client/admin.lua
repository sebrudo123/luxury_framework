-- luxury_core: Comandos y Herramientas Administrativas (Cliente)
local isNoclip = false
local noclipSpeed = 1.0
local isPlayerFrozen = false

--- Revivir al jugador local
RegisterNetEvent('luxury:admin:clientRevive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedTasksImmediately(ped)

    if Luxury and Luxury.Notify then
        Luxury.Notify('Has sido revivido por la administración', 'success')
    end
end)

--- Curar al jugador local
RegisterNetEvent('luxury:admin:clientHeal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)

    if Luxury and Luxury.Notify then
        Luxury.Notify('Has sido curado por la administración', 'success')
    end
end)

--- Ajustar armadura del jugador local
RegisterNetEvent('luxury:admin:clientArmor', function(amount)
    local ped = PlayerPedId()
    SetPedArmour(ped, math.max(0, math.min(100, tonumber(amount) or 100)))
end)

--- Espectear a otro jugador o salir del modo espectador
local isSpectating = false
local preSpectateCoords = nil

RegisterNetEvent('luxury:admin:clientSpectate', function(targetServerId, targetCoords)
    local ped = PlayerPedId()

    if not targetServerId then
        if isSpectating then
            NetworkSetInSpectatorMode(false, ped)
            SetEntityVisible(ped, true, false)
            FreezeEntityPosition(ped, false)
            SetEntityInvincible(ped, false)
            if preSpectateCoords then
                SetEntityCoordsNoOffset(ped, preSpectateCoords.x, preSpectateCoords.y, preSpectateCoords.z, false, false, false)
                preSpectateCoords = nil
            end
            isSpectating = false
            LocalPlayer.state:set('luxury:spectating', false, false)
            TriggerEvent('chat:addMessage', { args = { '^2[Espectador]^7', 'Has salido del modo espectador.' } })
        else
            TriggerEvent('chat:addMessage', { args = { '^3[Espectador]^7', 'Uso: ^3/spec [id]^7' } })
        end
        return
    end

    if not isSpectating then
        preSpectateCoords = GetEntityCoords(ped)
    end

    isSpectating = true
    LocalPlayer.state:set('luxury:spectating', true, false)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)

    if targetCoords then
        SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z + 10.0, false, false, false)
        RequestCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
    end

    Wait(250)
    local playerIdx = GetPlayerFromServerId(targetServerId)
    local targetPed = playerIdx ~= -1 and GetPlayerPed(playerIdx) or 0
    if targetPed ~= 0 and DoesEntityExist(targetPed) then
        NetworkSetInSpectatorMode(true, targetPed)
    end
end)

--- Cambiar matrícula del vehículo actual
RegisterNetEvent('luxury:admin:clientSetPlate', function(newPlate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if veh == 0 or not DoesEntityExist(veh) then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Debes estar dentro o cerca de un vehículo.' } })
    end

    local oldPlate = GetVehicleNumberPlateText(veh)
    SetVehicleNumberPlateText(veh, newPlate)
    TriggerServerEvent('luxury:admin:updateVehiclePlateDB', oldPlate, newPlate)
end)

--- Teletransporte seguro con colisión
RegisterNetEvent('luxury:admin:teleport', function(coords)
    local ped = PlayerPedId()
    local targetEntity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped

    SetEntityCoords(targetEntity, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, true)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
end)

--- Congelar jugador
RegisterNetEvent('luxury:admin:freeze', function(state)
    isPlayerFrozen = state
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    if state then
        ClearPedTasksImmediately(ped)
    end
end)

--- /tpm: Teletransporte al Punto de Ruta (Waypoint)
RegisterCommand('tpm', function()
    -- Comprobar permisos con State Bag
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'No tienes permisos de administrador.' } })
    end

    local waypointBlip = GetFirstBlipInfoId(8) -- 8 = Waypoint Blip en GTA V
    if not DoesBlipExist(waypointBlip) then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'No has marcado ningún punto de ruta en el mapa.' } })
    end

    local coords = GetBlipInfoIdCoord(waypointBlip)
    local ped = PlayerPedId()
    local entity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped

    -- Buscar altura Z correcta
    DoScreenFadeOut(200)
    Wait(250)

    local groundFound = false
    local groundZ = 0.0

    for z = 0.0, 950.0, 50.0 do
        SetEntityCoords(entity, coords.x, coords.y, z, false, false, false, true)
        RequestCollisionAtCoord(coords.x, coords.y, z)
        Wait(10)
        local found, zCoord = GetGroundZFor_3dCoord(coords.x, coords.y, z, false)
        if found then
            groundZ = zCoord + 1.0
            groundFound = true
            break
        end
    end

    if not groundFound then
        groundZ = coords.z + 50.0
    end

    SetEntityCoords(entity, coords.x, coords.y, groundZ, false, false, false, true)
    Wait(200)
    DoScreenFadeIn(200)
    TriggerEvent('chat:addMessage', { args = { '^2[Éxito]^7', 'Teletransportado al marcador del mapa.' } })
end, false)

--- /noclip: Modo Vuelo Libre
RegisterCommand('noclip', function()
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end

    isNoclip = not isNoclip
    local ped = PlayerPedId()
    local entity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped

    SetEntityCollision(entity, not isNoclip, not isNoclip)
    FreezeEntityPosition(entity, isNoclip)
    SetEntityInvincible(entity, isNoclip)
    SetEntityVisible(entity, not isNoclip, false)

    if not isNoclip then
        SetEntityVelocity(entity, 0.0, 0.0, 0.0)
        return
    end

    CreateThread(function()
        while isNoclip do
            Wait(0)
            local currentEntity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or PlayerPedId()
            local coords = GetEntityCoords(currentEntity)
            local camRot = GetGameplayCamRot(2)

            -- Manejo de velocidad con SHIFT (rápido) o CTRL (lento)
            local speed = noclipSpeed
            if IsControlPressed(0, 21) then -- SHIFT
                speed = speed * 3.5
            elseif IsControlPressed(0, 36) then -- CTRL
                speed = speed * 0.25
            end

            local radX = math.rad(camRot.x)
            local radZ = math.rad(camRot.z)
            local numSinZ = -math.sin(radZ)
            local numCosZ = math.cos(radZ)
            local numSinX = math.sin(radX)
            local numCosX = math.cos(radX)

            local forward = vector3(numSinZ * numCosX, numCosZ * numCosX, numSinX)
            local right = vector3(numCosZ, -numSinZ, 0.0)

            local moveVector = vector3(0.0, 0.0, 0.0)

            -- W / S (Adelante / Atrás)
            if IsControlPressed(0, 32) then moveVector = moveVector + forward end
            if IsControlPressed(0, 33) then moveVector = moveVector - forward end

            -- A / D (Izquierda / Derecha)
            if IsControlPressed(0, 34) then moveVector = moveVector - right end
            if IsControlPressed(0, 35) then moveVector = moveVector + right end

            -- ESPACIO (Subir) / SHIFT alternativo
            if IsControlPressed(0, 22) then moveVector = moveVector + vector3(0.0, 0.0, 1.0) end

            local newCoords = coords + (moveVector * speed)
            SetEntityCoordsNoOffset(currentEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
            SetEntityHeading(currentEntity, camRot.z)
        end
    end)
end, false)

--- /car [modelo]: Spawnear vehículo
RegisterCommand('car', function(_, args)
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end

    local model = args[1] or 'adder'
    local hash = joaat(model)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Modelo de vehículo inexistente.' } })
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)
    TriggerEvent('chat:addMessage', { args = { '^2[Éxito]^7', ('Vehículo ^3%s^7 generado.'):format(model) } })
end, false)

--- /dv [radio opcional]: Borrar vehículo actual o vehículos en el radio cercano
RegisterCommand('dv', function(_, args)
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end

    local radius = tonumber(args[1])
    local ped = PlayerPedId()

    if radius and radius > 0 then
        local pCoords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')
        local count = 0
        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) and #(pCoords - GetEntityCoords(veh)) <= radius then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteVehicle(veh)
                count = count + 1
            end
        end
        return TriggerEvent('chat:addMessage', { args = { '^2[Éxito]^7', ('Se eliminaron ^3%d^7 vehículos en un radio de %d metros.'):format(count, radius) } })
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if veh ~= 0 and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        TriggerEvent('chat:addMessage', { args = { '^2[Éxito]^7', 'Vehículo eliminado correctamente.' } })
    else
        TriggerEvent('chat:addMessage', { args = { '^1[Aviso]^7', 'No hay ningún vehículo cercano para borrar.' } })
    end
end, false)

--- /fix o /reparar: Reparar y limpiar vehículo
local function repairVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if veh == 0 or not DoesEntityExist(veh) then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'No estás en un vehículo ni hay ninguno cerca para reparar.' } })
    end

    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleUndriveable(veh, false)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)

    for i = 0, 7 do
        SetVehicleTyreFixed(veh, i)
    end

    TriggerEvent('chat:addMessage', { args = { '^2[Éxito]^7', 'Vehículo reparado y limpiado completamente.' } })
    if Luxury and Luxury.Notify then
        Luxury.Notify('Vehículo reparado con éxito', 'success')
    end
end

RegisterCommand('fix', function()
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end
    repairVehicle()
end, false)

RegisterCommand('reparar', function()
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end
    repairVehicle()
end, false)

--- /coords o /coordenadas: Muestra coordenadas detalladas
local function printCoords()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local v3 = string.format('vector3(%.2f, %.2f, %.2f)', coords.x, coords.y, coords.z)
    local v4 = string.format('vector4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, heading)

    print(('[luxury_core] Coordenadas: %s'):format(v3))
    print(('[luxury_core] Coordenadas: %s'):format(v4))

    TriggerEvent('chat:addMessage', {
        args = { '^3[Coordenadas]^7', ('^2v3:^7 %s | ^2Heading:^7 %.2f'):format(v3, heading) }
    })
    TriggerEvent('chat:addMessage', {
        args = { '^3[Coordenadas]^7', ('^2v4:^7 %s'):format(v4) }
    })

    if Luxury and Luxury.Notify then
        Luxury.Notify('Coordenadas impresas en consola F8 y chat', 'info')
    end
end

RegisterCommand('coords', function()
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end
    printCoords()
end, false)

RegisterCommand('coordenadas', function()
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end
    printCoords()
end, false)
