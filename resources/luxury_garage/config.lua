-- luxury_garage: Configuración Completa
Config = {}

Config.Locale = 'es'
Config.Currency = '$'
Config.ImpoundFee = 1500 -- Precio de rescate del vehículo en el Depósito
Config.LockKey = 'U'     -- Tecla para abrir/cerrar vehículo con mando

-- Garajes Públicos Distribuidos por el Mapa
Config.Garages = {
    ['LegionSquare'] = {
        label = 'Garaje Central Legion Square',
        type = 'car',
        marker = vector3(215.12, -810.15, 30.73),
        spawn = vector4(218.44, -805.12, 30.55, 335.0)
    },
    ['Vinewood'] = {
        label = 'Garaje Vinewood Hills',
        type = 'car',
        marker = vector3(600.25, 275.12, 103.35),
        spawn = vector4(605.18, 271.45, 103.15, 245.0)
    },
    ['SandyShores'] = {
        label = 'Garaje Sandy Shores',
        type = 'car',
        marker = vector3(1734.25, 3712.18, 34.15),
        spawn = vector4(1738.12, 3708.55, 34.02, 115.0)
    },
    ['PaletoBay'] = {
        label = 'Garaje Paleto Boulevard',
        type = 'car',
        marker = vector3(-113.12, 6480.25, 31.52),
        spawn = vector4(-109.45, 6476.18, 31.42, 45.0)
    }
}

-- Depósitos / Incautados (Impounds)
Config.Impounds = {
    ['CityImpound'] = {
        label = 'Depósito Municipal de Los Santos',
        marker = vector3(409.15, -1623.45, 29.29),
        spawn = vector4(404.22, -1635.18, 29.29, 230.0),
        fee = 1500
    }
}
