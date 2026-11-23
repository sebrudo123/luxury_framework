-- luxury_core: Puente de Compatibilidad con Qbox (qbx_core)
qbx = qbx or {}

-- Qbox se apoya en ox_lib y en estructuras similares a QBCore
-- Proveemos exports compatibles con qbx_core para scripts modernos basados en Qbox

exports('GetQboxPlayer', function(source)
    return exports.luxury_core:GetPlayer(source)
end)

-- Notificaciones compatibles con lib.notify / qbx
RegisterNetEvent('qbx_core:client:notify', function(text, notifyType, duration)
    if Luxury and Luxury.Notify then
        Luxury.Notify(text, notifyType or 'info', duration or 4000)
    end
end)
