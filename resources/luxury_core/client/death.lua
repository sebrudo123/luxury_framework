-- luxury_core: Sistema de Muerte, Inconsciencia y Hospital (Cliente)
local isDead = false
local bleedoutTimer = 0

-- Detección continua de muerte o incapacidad
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if LocalPlayer.state.isLoggedIn then
            if IsEntityDead(ped) and not isDead then
                isDead = true
                TriggerServerEvent('luxury:server:setDeadState', true)
                StartDeathSequence()
            end
        end

        Wait(sleep)
    end
end)

function StartDeathSequence()
    bleedoutTimer = Config.BleedoutTimer or 300

    -- Efecto visual cinematográfico en blanco y negro
    AnimpostfxPlay('DeathFailNeutralIn', 0, true)

    CreateThread(function()
        while isDead and bleedoutTimer > 0 do
            Wait(1000)
            bleedoutTimer = bleedoutTimer - 1
        end
    end)

    CreateThread(function()
        while isDead do
            Wait(0)
            local ped = PlayerPedId()

            -- Mantener al ped inconsciente en el suelo
            SetEntityInvincible(ped, true)
            SetPedCanRagdoll(ped, true)

            -- Mostrar información en pantalla
            local minutes = math.floor(bleedoutTimer / 60)
            local seconds = bleedoutTimer % 60
            local timeText = string.format("%02d:%02d", minutes, seconds)

            if bleedoutTimer > 0 then
                Draw2DText(0.5, 0.88, ('~r~ESTÁS INCONSCIENTE~s~ | Esperando asistencia médica (~y~%s~s~)'):format(timeText), 0.45)
            else
                Draw2DText(0.5, 0.88, '~r~EN COMA PROFUNDO~s~ | Mantén pulsado ~g~[E]~s~ para reaparecer en el hospital', 0.45)
                if IsControlPressed(0, 38) then -- Tecla [E]
                    RespawnAtHospital()
                    break
                end
            end
        end
    end)
end

function RespawnAtHospital()
    DoScreenFadeOut(800)
    Wait(1000)

    TriggerServerEvent('luxury:server:respawnAtHospital')
end

RegisterNetEvent('luxury:client:hospitalRespawn', function(coords)
    local ped = PlayerPedId()
    coords = coords or Config.HospitalCoords

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.heading or 0.0, true, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.heading or 0.0)

    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, 200)
    SetEntityInvincible(ped, false)
    ClearPedTasksImmediately(ped)

    AnimpostfxStop('DeathFailNeutralIn')
    isDead = false
    TriggerServerEvent('luxury:server:setDeadState', false)

    Wait(500)
    DoScreenFadeIn(800)

    if Luxury and Luxury.Notify then
        Luxury.Notify('Te has despertado en el Hospital Pillbox Hill', 'info', 5000)
    end
end)

-- Cuando reviven al jugador por comando o EMS
RegisterNetEvent('luxury:client:revivePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, 200)
    SetEntityInvincible(ped, false)
    ClearPedTasksImmediately(ped)

    AnimpostfxStop('DeathFailNeutralIn')
    isDead = false
    TriggerServerEvent('luxury:server:setDeadState', false)
end)

function Draw2DText(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

exports('IsDead', function()
    return isDead
end)
