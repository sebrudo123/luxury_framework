-- luxury_core: Sistema de Necesidades (Hambre y Sed - Cliente)

-- Vigilancia del estado de salud por inanición o deshidratación
CreateThread(function()
    while true do
        Wait(Config.Status.TickInterval or 60000)

        if LocalPlayer.state.isLoggedIn and not LocalPlayer.state.isDead then
            local hunger = LocalPlayer.state.hunger or 100
            local thirst = LocalPlayer.state.thirst or 100
            local ped = PlayerPedId()

            -- Si el hambre o la sed llegan a 0, el jugador comienza a perder vida gradualmente
            if hunger <= 0 or thirst <= 0 then
                local currentHealth = GetEntityHealth(ped)
                local damage = Config.Status.StarvationDamage or 5
                local newHealth = math.max(0, currentHealth - damage)

                SetEntityHealth(ped, newHealth)

                if Luxury and Luxury.Notify then
                    Luxury.Notify('Estás sufriendo deshidratación o inanición severa', 'warning', 4000)
                end
            end
        end
    end
end)

-- Exports del cliente para interfaces / HUDs
exports('GetStatus', function()
    return {
        hunger = LocalPlayer.state.hunger or 100,
        thirst = LocalPlayer.state.thirst or 100
    }
end)
