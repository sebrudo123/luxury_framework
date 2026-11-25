-- luxury_core: Configuración Exclusiva del Cliente
Config = Config or {}

-- Controles y Teclas
Config.Keys = {
    Interact = 38, -- [E] Tecla para reaparecer en hospital o interactuar
}

-- Notificaciones y HUD
Config.NotifyDuration = 4000

-- Calidad de Vida y Reglas del Mundo Roleplay (0.00ms Resmon)
Config.EnablePvP = true                -- Habilitar combate PvP entre jugadores
Config.DisableWantedLevel = true       -- Desactivar estrellas de búsqueda policial de GTA V
Config.DisableNPCDepartments = true    -- Desactivar spawn de policías/ambulancias/bomberos NPC
Config.DisableNPCWeaponDrops = true    -- Evitar que los NPCs suelten armas al morir
Config.DisablePistolWhip = true        -- Bloquear golpe instantáneo con [R] al portar arma de fuego

-- Discord Rich Presence (Opcional: pon tu AppId de Discord Developer Portal y Enabled = true)
Config.RichPresence = {
    Enabled = false,
    AppId = '',
    AssetName = 'logo',
    AssetText = 'New Empire Roleplay',
    SmallAsset = 'logo',
    SmallText = 'Luxury Framework'
}
