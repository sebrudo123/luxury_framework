-- luxury_hud: Configuración Abierta Origen HUD (Escrow Ignored)
Config = Config or {}

-- Diseño por defecto: 'circular' (Estilo Origen HUD clásico) o 'horizontal'
Config.Layout = 'circular'

-- Ocultar iconos de estado cuando estén al 100% (Modo Dinámico)
Config.DynamicVitals = false

-- Unidad de medida de velocidad: 'kmh' o 'mph'
Config.SpeedUnit = 'kmh'

-- Mostrar brújula y nombre de calles sobre el minimapa
Config.ShowCompass = true
Config.ShowStreet = true

-- Frecuencias de refresco de telemetría (milisegundos)
Config.FootRefresh = 250
Config.VehicleRefresh = 50

-- Ocultar el HUD al morir
Config.HideOnDead = true

-- Comando para abrir el Menú de Ajustes del HUD
Config.SettingsCommand = 'hud'

-- Comando para activar modo cinemático (bandas negras formato 21:9)
Config.CinematicCommand = 'cinematic'

-- Tecla por defecto del Cinturón de Seguridad
Config.SeatbeltKey = 'B'

-- Paleta de Colores Oficial Origen HUD
Config.Colors = {
    voice = '#a855f7',
    health = '#ef4444',
    armor = '#3b82f6',
    hunger = '#f59e0b',
    thirst = '#06b6d4',
    stamina = '#10b981',
    stress = '#ec4899',
    oxygen = '#38bdf8'
}
