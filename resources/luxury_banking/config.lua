-- luxury_banking: Configuración okokBanking Replica (FiveM Edition)
Config = {}

-- Configuración General
Config.Locale = 'es'
Config.Currency = '$'
Config.BankName = 'okokBanking'
Config.IBANPrefix = 'OKOK-'

-- Comisiones
Config.ATMFeePercentage = 2.0  -- 2% de comisión en cajeros de la calle
Config.BankFeePercentage = 0.0 -- 0% de comisión en bancos físicos

-- Cantidades de acceso rápido
Config.QuickAmounts = { 100, 500, 1000, 2500, 5000, 10000 }
Config.ATMQuickAmounts = { 100, 200, 500, 1000, 2000, 5000 }

-- Modelos de Cajeros Automáticos (ATMs)
Config.ATMProps = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

-- Ubicaciones de Bancos Físicos
Config.Banks = {
    { name = 'Fleeca Bank Legion Square', coords = vector3(149.24, -1040.43, 29.37) },
    { name = 'Fleeca Bank Hawick Ave', coords = vector3(314.18, -278.62, 54.17) },
    { name = 'Fleeca Bank Del Perro', coords = vector3(-1212.98, -330.84, 37.78) },
    { name = 'Fleeca Bank Great Ocean Hwy', coords = vector3(-2962.60, 482.17, 15.70) },
    { name = 'Fleeca Bank Boulevard Del Perro', coords = vector3(-351.53, -49.52, 49.04) },
    { name = 'Fleeca Bank Route 68', coords = vector3(1175.06, 2706.64, 38.09) },
    { name = 'Fleeca Bank Paleto Bay', coords = vector3(-112.79, 6467.75, 31.62) },
    { name = 'Pacific Standard Public Bank', coords = vector3(252.36, 221.43, 106.29) }
}
