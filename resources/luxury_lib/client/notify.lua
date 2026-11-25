-- luxury_lib: Sistema de Notificaciones adaptable (integrado con luxury_notify)
Luxury = Luxury or {}

--- Muestra una notificación en la interfaz del jugador
-- @param data string|table: Mensaje de texto o tabla con { title, description, type, duration }
-- @param notifyType string|nil: 'success', 'error', 'info', 'warning' (si data es string)
-- @param duration number|nil: Duración en milisegundos
function Luxury.Notify(data, notifyType, duration)
    local title = nil
    local msg = ''
    local nType = 'info'
    local dur = 4000

    if type(data) == 'table' then
        title = data.title
        msg = data.description or data.message or ''
        nType = data.type or 'info'
        dur = data.duration or 4000
    else
        msg = tostring(data or '')
        nType = notifyType or 'info'
        dur = duration or 4000
    end

    local defaultTitles = {
        success = 'Éxito',
        error = 'Error',
        warning = 'Aviso',
        info = 'Información'
    }

    if GetResourceState('luxury_notify') == 'started' then
        local ok = pcall(function()
            exports['luxury_notify']:Alert(title or defaultTitles[nType] or 'Sistema', msg, dur, nType)
        end)
        if ok then return end
    end

    -- Fallback nativo limpio si luxury_notify no está iniciado
    BeginTextCommandThefeedPost("STRING")
    local prefix = {
        success = "~g~[ÉXITO]~s~ ",
        error = "~r~[ERROR]~s~ ",
        warning = "~y~[AVISO]~s~ ",
        info = "~b~[INFO]~s~ "
    }
    AddTextComponentSubstringPlayerName((prefix[nType] or "") .. msg)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('luxury:lib:notify', function(data, notifyType, duration)
    Luxury.Notify(data, notifyType, duration)
end)

exports('Notify', Luxury.Notify)
