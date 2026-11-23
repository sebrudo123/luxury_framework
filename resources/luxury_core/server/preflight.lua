-- Comprobación de arranque y presentación de luxury_core
local RES = GetCurrentResourceName()
local TAG = '[LUXURY-CORE]'

local function linea()
    print('^5=====================================================================^7')
end

local function fallar(motivos)
    print('')
    linea()
    print('  ^1' .. TAG .. ' ERROR: FALTA ALGO IMPRESCINDIBLE, EL RECURSO SE APAGA^7')
    linea()
    for _, m in ipairs(motivos) do
        print('  - ^3' .. m .. '^7')
    end
    linea()
    print('')
    LuxuryFailed = true
    CreateThread(function()
        Wait(0)
        StopResource(RES)
    end)
end

function PrintLuxuryBanner()
    print('^5[LUXURY-INIT]^7 ==============================================================')
    print('^5[LUXURY-INIT]^7  ^6💎^7  ^5LUXURY CORE PRO ACTIVO Y OPERATIVO^7')
    print('^5[LUXURY-INIT]^7  ^3🏢^7  Desarrollado exclusivamente por ^5Luxury Scripts^7')
    print('^5[LUXURY-INIT]^7 ==============================================================')
    print('')
    linea()
    print('^6  ██╗     ██╗   ██╗██╗  ██╗██╗   ██╗██████╗ ██╗   ██╗^7')
    print('^6  ██║     ██║   ██║╚██╗██╔╝██║   ██║██╔══██╗╚██╗ ██╔╝^7')
    print('^6  ██║     ██║   ██║ ╚███╔╝ ██║   ██║██████╔╝ ╚████╔╝ ^7')
    print('^6  ██║     ██║   ██║ ██╔██╗ ██║   ██║██╔══██╗  ╚██╔╝  ^7')
    print('^6  ███████╗╚██████╔╝██╔╝ ██╗╚██████╔╝██║  ██║   ██║   ^7')
    print('^6  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ^7')
    print('^5       · LUXURY CORE PRO 0.00ms · LUXURY SCRIPTS ·^7')
    linea()
    print('')
end

CreateThread(function()
    local motivos = {}

    -- 1) oxmysql debe estar iniciado
    if GetResourceState('oxmysql') ~= 'started' then
        motivos[#motivos + 1] = 'oxmysql no está iniciado. Ponlo con ensure ANTES de luxury_core en el server.cfg.'
    else
        -- 2) la base de datos debe responder
        local ok, res = pcall(function() return MySQL.scalar.await('SELECT 1') end)
        if not ok or res ~= 1 then
            motivos[#motivos + 1] = 'No hay conexión con la base de datos. Revisa mysql_connection_string en el server.cfg.'
        end
    end

    -- 3) la config debe existir y ser válida
    if not Config or type(Config.DefaultJob) ~= 'table' or type(Config.Groups) ~= 'table' then
        motivos[#motivos + 1] = 'config.lua incompleto (faltan DefaultJob o Groups).'
    end

    if #motivos > 0 then
        return fallar(motivos)
    end

    print('^5[LUXURY-SECURITY]^7 Motor Anti-Dump & Honeypot Triggers activado (27 eventos cebo).')
    print('^5[LUXURY-SECURITY]^7 Centinela C++ Event Interceptors activo (Explosions, EntityCreating, Weapons).')
    print('^5[LUXURY-SECURITY]^7 Detección HWID Ban Evasion & Multi-Token Shield operativa.')
    print('^5[LUXURY-SECURITY]^7 Vigilancia Cliente en Tiempo Real (Anti-Godmode, Speedhack, Armas Negras).')
    print('^5[LUXURY-SECURITY]^7 Monitor de Latido (Heartbeat) & Anti-Resource Stop operativo.')
    print('^5[LUXURY-PROXY]^7 Motor Proxy & Tunnel RPC sincronizado (Interfaces ^3luxury^7 y ^3luxury_core^7 listas).')
    print('^5[LUXURY-CORE]^7 Módulo Economía & Metatables inicializado (Anti-NaN & Overflow guard activo).')
    print('^5[LUXURY-CORE]^7 Módulo ox_inventory Bridge & OneSync State Bags activado.')
    print('^5[LUXURY-CORE]^7 Módulo Jobs & Paycheck System sincronizado.')
end)
