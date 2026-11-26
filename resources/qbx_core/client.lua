-- luxury_core: Puente Cliente para scripts Qbox (qbx_core)
local function getQBCore()
    return exports['luxury_core']:GetQBCore()
end

exports('GetCoreObject', function()
    return getQBCore()
end)

exports('Notify', function(text, notifyType, duration)
    local msg = type(text) == 'table' and (text.description or text.title or '') or tostring(text or '')
    if exports['luxury_notify'] then
        exports['luxury_notify']:Alert('Notificación', msg, duration or 4000, notifyType or 'info')
    else
        TriggerEvent('chat:addMessage', {
            color = { 212, 175, 55 },
            args = { 'Qbox', msg }
        })
    end
end)
