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

--- /dv: Borrar vehículo actual o más cercano
RegisterCommand('dv', function()
    local playerGroup = LocalPlayer.state['luxury:data'] and LocalPlayer.state['luxury:data'].group or 'user'
    if playerGroup ~= 'admin' and playerGroup ~= 'mod' then
        return TriggerEvent('chat:addMessage', { args = { '^1[Error]^7', 'Sin permisos.' } })
    end

    local ped = PlayerPedId()
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
