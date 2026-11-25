-- luxury_core: Bucles de Fondo, Calidad de Vida RP y Discord Rich Presence (Cliente)

-- 1) Configuración inicial del mundo GTA V al cargar personaje (ejecución única, 0.00ms)
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    if Config.EnablePvP ~= false then
        NetworkSetFriendlyFireOption(true)
        SetCanAttackFriendly(PlayerPedId(), true, false)
    end

    if Config.DisableWantedLevel ~= false then
        SetMaxWantedLevel(0)
        ClearPlayerWantedLevel(PlayerId())
    end

    if Config.DisableNPCDepartments ~= false then
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
    end

    if Config.DisableNPCWeaponDrops ~= false then
        SetPedDropsWeaponsWhenDead(PlayerPedId(), false)
    end
end)

-- 2) Prevención de Pistol Whip [R] cuando se sostiene arma de fuego (solo consume ticks al estar armado)
CreateThread(function()
    while true do
        local sleep = 500
        if Config.DisablePistolWhip ~= false and LocalPlayer.state.isLoggedIn and not LocalPlayer.state.isDead then
            local ped = PlayerPedId()
            if IsPedArmed(ped, 6) then
                sleep = 0
                DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT (R)
                DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY (Q)
                DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            end
        end
        Wait(sleep)
    end
end)

-- 3) Sincronización periódica de coordenadas con el servidor
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

-- 4) Discord Rich Presence dinámico (si está habilitado en config/client.lua)
CreateThread(function()
    while true do
        Wait(30000)
        local rp = Config.RichPresence
        if rp and rp.Enabled and rp.AppId and rp.AppId ~= '' and LocalPlayer.state.isLoggedIn then
            SetDiscordAppId(rp.AppId)
            SetDiscordRichPresenceAsset(rp.AssetName or 'logo')
            SetDiscordRichPresenceAssetText(rp.AssetText or 'Luxury Framework')
            if rp.SmallAsset then
                SetDiscordRichPresenceAssetSmall(rp.SmallAsset)
                SetDiscordRichPresenceAssetSmallText(rp.SmallText or '')
            end
            local jobLabel = (PlayerData and PlayerData.job and PlayerData.job.label) or 'Ciudadano'
            local pCount = #GetActivePlayers()
            SetRichPresence(('ID: %d | %s | %d jugadores cerca'):format(GetPlayerServerId(PlayerId()), jobLabel, pCount))
        end
    end
end)
