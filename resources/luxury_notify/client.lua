-- luxury_notify: Lógica de Cliente y Exportador Universal
-- Compatible con ESX, QBCore y Luxury Framework

local isTextUIOpen = false

--- Mostrar Notificación Flotante
-- @param title string
-- @param message string
-- @param duration number (ms, por defecto 4000)
-- @param nType string ('success', 'error', 'info', 'warning')
function Alert(title, message, duration, nType)
    if not message and title then
        message = title
        title = (nType == 'error' and 'Error') or (nType == 'success' and 'Éxito') or 'Notificación'
    end
    SendNUIMessage({
        action = 'NOTIFY',
        payload = {
            title = title or 'Aviso',
            message = message or '',
            duration = tonumber(duration) or 4000,
            type = nType or 'info'
        }
    })
end

--- Mostrar TextUI / Prompt de Interacción Flotante
-- @param text string
-- @param position string ('right', 'left', 'center')
function ShowTextUI(text, position)
    isTextUIOpen = true
    SendNUIMessage({
        action = 'SHOW_TEXTUI',
        payload = {
            text = text or '',
            position = position or 'right'
        }
    })
end

--- Ocultar TextUI
function HideTextUI()
    if isTextUIOpen then
        isTextUIOpen = false
        SendNUIMessage({
            action = 'HIDE_TEXTUI'
        })
    end
end

-- Exports
exports('Alert', Alert)
exports('Notify', Alert)
exports('TextUI', ShowTextUI)
exports('HideUI', HideTextUI)

-- Eventos de Red
RegisterNetEvent('luxury_notify:Alert', Alert)
RegisterNetEvent('luxury_notify:Notify', Alert)
RegisterNetEvent('luxury_notify:TextUI', ShowTextUI)
RegisterNetEvent('luxury_notify:HideUI', HideTextUI)

-- Sustitución directa de notificaciones clásicas de ESX
RegisterNetEvent('esx:showNotification', function(msg, nType)
    local mappedType = 'info'
    if nType == 'error' or nType == 'success' or nType == 'warning' then
        mappedType = nType
    elseif type(msg) == 'string' then
        if msg:find('~r~') then mappedType = 'error'
        elseif msg:find('~g~') then mappedType = 'success'
        elseif msg:find('~y~') then mappedType = 'warning'
        end
        -- Limpiar etiquetas de color clásicas de GTA
        msg = msg:gsub('~[a-z]~', '')
    end
    Alert('Notificación', msg, 4000, mappedType)
end)
