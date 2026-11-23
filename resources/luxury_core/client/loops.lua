-- luxury_core: Bucles de Fondo del Cliente (Client Loops)

-- Sincronización periódica de coordenadas con el servidor
CreateThread(function()
    while true do
        Wait(Config.CoordsSyncInterval or 60000)

        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                TriggerServerEvent('luxury:server:updateCoords', {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = heading
                })
            end
        end
    end
end)
