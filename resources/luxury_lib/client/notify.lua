-- luxury_lib: Sistema de Notificaciones adaptable
Luxury = Luxury or {}

--- Muestra una notificación en la interfaz del jugador
-- @param data string|table: Mensaje de texto o tabla con { title, description, type, duration }
-- @param notifyType string|nil: 'success', 'error', 'info', 'warning' (si data es string)
-- @param duration number|nil: Duración en milisegundos
function Luxury.Notify(data, notifyType, duration)
    local msg = ''
    local nType = 'info'
    local dur = 4000

    if type(data) == 'table' then
        msg = data.description or data.message or ''
        nType = data.type or 'info'
        dur = data.duration or 4000
    else
        msg = tostring(data)
        nType = notifyType or 'info'
        dur = duration or 4000
    end

    -- Evento extensible: si tienes un HUD/UI propio, puedes interceptar este evento
    local handled = false
    -- Fallback nativo limpio: subtítulo de GTA V o mensaje formateado
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
