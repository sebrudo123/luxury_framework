-- Cliente compatible con Qbox
RegisterNetEvent('qbx_core:client:notify', function(text, notifyType, duration)
    if Luxury and Luxury.Notify then
        Luxury.Notify(text, notifyType or 'info', duration or 4000)
    end
end)
