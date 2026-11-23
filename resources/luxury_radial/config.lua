-- luxury_radial: Configuración del Menú Radial
Config = {}

Config.MenuKey = 'F1' -- Tecla predeterminada para abrir el menú radial
Config.EnableSound = true

-- Opciones Generales para Ciudadano a Pie
Config.CitizenItems = {
    {
        id = 'citizen_id',
        label = 'Documento DNI',
        icon = 'id',
        action = 'show_id'
    },
    {
        id = 'vehicle_keys',
        label = 'Dar Llaves',
        icon = 'key',
        action = 'give_keys'
    },
    {
        id = 'clothes_menu',
        label = 'Ropa & Accesorios',
        icon = 'shirt',
        items = {
            { id = 'cloth_mask', label = 'Máscara', icon = 'mask', action = 'toggle_mask' },
            { id = 'cloth_hat', label = 'Sombrero', icon = 'hat', action = 'toggle_hat' },
            { id = 'cloth_glasses', label = 'Gafas', icon = 'glasses', action = 'toggle_glasses' },
            { id = 'cloth_vest', label = 'Chaleco', icon = 'vest', action = 'toggle_vest' }
        }
    },
    {
        id = 'emotes_quick',
        label = 'Animaciones',
        icon = 'user',
        items = {
            { id = 'emote_crossarms', label = 'Cruzar Brazos', icon = 'user', action = 'emote_crossarms' },
            { id = 'emote_sit', label = 'Sentarse', icon = 'user', action = 'emote_sit' },
            { id = 'emote_surrender', label = 'Rendirse', icon = 'user', action = 'emote_surrender' },
            { id = 'emote_salute', label = 'Saludar', icon = 'user', action = 'emote_salute' }
        }
    }
}

-- Opciones cuando el Jugador está Dentro de un Vehículo
Config.VehicleItems = {
    {
        id = 'veh_engine',
        label = 'Alternar Motor',
        icon = 'engine',
        action = 'toggle_engine'
    },
    {
        id = 'veh_doors',
        label = 'Puertas',
        icon = 'doors',
        items = {
            { id = 'door_hood', label = 'Capó', icon = 'doors', action = 'door_hood' },
            { id = 'door_trunk', label = 'Maletero', icon = 'doors', action = 'door_trunk' },
            { id = 'door_fl', label = 'Delantera Izq', icon = 'doors', action = 'door_fl' },
            { id = 'door_fr', label = 'Delantera Der', icon = 'doors', action = 'door_fr' },
            { id = 'door_rl', label = 'Trasera Izq', icon = 'doors', action = 'door_rl' },
            { id = 'door_rr', label = 'Trasera Der', icon = 'doors', action = 'door_rr' }
        }
    },
    {
        id = 'veh_windows',
        label = 'Ventanillas',
        icon = 'window',
        action = 'toggle_windows'
    },
    {
        id = 'veh_seats',
        label = 'Cambiar Asiento',
        icon = 'seat',
        items = {
            { id = 'seat_driver', label = 'Conductor', icon = 'seat', action = 'seat_driver' },
            { id = 'seat_passenger', label = 'Copiloto', icon = 'seat', action = 'seat_passenger' },
            { id = 'seat_rear_l', label = 'Trasero Izq', icon = 'seat', action = 'seat_rear_l' },
            { id = 'seat_rear_r', label = 'Trasero Der', icon = 'seat', action = 'seat_rear_r' }
        }
    }
}
