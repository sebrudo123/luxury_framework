-- luxury_radial: Lógica de Cliente y Acciones Físicas
-- Compatible con ESX, QBCore y Luxury Framework

local isRadialOpen = false

--- KeyMapping para Abrir el Menú Radial
RegisterKeyMapping('openRadialMenu', 'Abrir Menú Radial', 'keyboard', Config.MenuKey or 'F1')
RegisterCommand('openRadialMenu', function()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or isRadialOpen then return end

    local inVehicle = IsPedInAnyVehicle(ped, false)
    local items = inVehicle and Config.VehicleItems or Config.CitizenItems

    isRadialOpen = true
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
    SendNUIMessage({
        action = 'OPEN_RADIAL',
        payload = {
            inVehicle = inVehicle,
            items = items
        }
    })
end, false)

--- NUI Callback: Cerrar Menú Radial
RegisterNUICallback('close', function(_, cb)
    isRadialOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

--- NUI Callback: Ejecutar Acción Seleccionada
RegisterNUICallback('executeAction', function(data, cb)
    isRadialOpen = false
    SetNuiFocus(false, false)

    local action = data.action
    local ped = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(ped, false)
    local veh = inVehicle and GetVehiclePedIsIn(ped, false) or 0

    -- 1. Control del Motor
    if action == 'toggle_engine' and inVehicle then
        local isRunning = GetIsVehicleEngineRunning(veh)
        SetVehicleEngineOn(veh, not isRunning, false, true)
        if exports['luxury_notify'] then
            exports['luxury_notify']:Alert('Vehículo', isRunning and 'Motor apagado.' or 'Motor encendido.', 2500, 'info')
        end

    -- 2. Control de Puertas del Vehículo
    elseif action:find('^door_') and inVehicle then
        local doorMap = {
            ['door_fl'] = 0,
            ['door_fr'] = 1,
            ['door_rl'] = 2,
            ['door_rr'] = 3,
            ['door_hood'] = 4,
            ['door_trunk'] = 5
        }
        local doorIndex = doorMap[action]
        if doorIndex then
            local isOpen = GetVehicleDoorAngleRatio(veh, doorIndex) > 0.1
            if isOpen then
                SetVehicleDoorShut(veh, doorIndex, false)
            else
                SetVehicleDoorOpen(veh, doorIndex, false, false)
            end
        end

    -- 3. Control de Ventanillas
    elseif action == 'toggle_windows' and inVehicle then
        local areOpen = false
        for i = 0, 3 do
            if not IsVehicleWindowIntact(veh, i) then areOpen = true break end
        end
        if areOpen then
            RollUpWindow(veh, 0)
            RollUpWindow(veh, 1)
            RollUpWindow(veh, 2)
            RollUpWindow(veh, 3)
        else
            RollDownWindows(veh)
        end

    -- 4. Cambio de Asiento
    elseif action:find('^seat_') and inVehicle then
        local seatMap = {
            ['seat_driver'] = -1,
            ['seat_passenger'] = 0,
            ['seat_rear_l'] = 1,
            ['seat_rear_r'] = 2
        }
        local seatIndex = seatMap[action]
        if seatIndex and IsVehicleSeatFree(veh, seatIndex) then
            TaskWarpPedIntoVehicle(ped, veh, seatIndex)
        end

    -- 5. Accesorios y Ropa
    elseif action == 'toggle_mask' then
        local cur = GetPedDrawableVariation(ped, 1)
        SetPedComponentVariation(ped, 1, cur > 0 and 0 or 1, 0, 2)
    elseif action == 'toggle_hat' then
        local cur = GetPedPropIndex(ped, 0)
        if cur >= 0 then ClearPedProp(ped, 0) else SetPedPropIndex(ped, 0, 0, 0, true) end
    elseif action == 'toggle_glasses' then
        local cur = GetPedPropIndex(ped, 1)
        if cur >= 0 then ClearPedProp(ped, 1) else SetPedPropIndex(ped, 1, 0, 0, true) end
    elseif action == 'toggle_vest' then
        local cur = GetPedDrawableVariation(ped, 9)
        SetPedComponentVariation(ped, 9, cur > 0 and 0 or 1, 0, 2)

    -- 6. Animaciones Rápidas
    elseif action == 'emote_crossarms' then
        RequestAnimDict("amb@world_human_hang_out_street@female_arms_crossed@base")
        while not HasAnimDictLoaded("amb@world_human_hang_out_street@female_arms_crossed@base") do Wait(10) end
        TaskPlayAnim(ped, "amb@world_human_hang_out_street@female_arms_crossed@base", "base", 8.0, 8.0, -1, 49, 0, false, false, false)
    elseif action == 'emote_surrender' then
        RequestAnimDict("random@arrests@busted")
        while not HasAnimDictLoaded("random@arrests@busted") do Wait(10) end
        TaskPlayAnim(ped, "random@arrests@busted", "idle_a", 8.0, 8.0, -1, 49, 0, false, false, false)
    elseif action == 'emote_salute' then
        RequestAnimDict("anim@mp_player_intuppersalute")
        while not HasAnimDictLoaded("anim@mp_player_intuppersalute") do Wait(10) end
        TaskPlayAnim(ped, "anim@mp_player_intuppersalute", "idle_a", 8.0, 8.0, 2000, 48, 0, false, false, false)

    -- 7. Documento DNI
    elseif action == 'show_id' then
        TriggerServerEvent('luxury_radial:server:showIdCard')
    end

    cb('ok')
end)
