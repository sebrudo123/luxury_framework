-- luxury_core: Puente de Compatibilidad con Qbox (qbx_core)
qbx = qbx or {}

-- Qbox utiliza una estructura compatible con QBCore (PlayerData + Functions)
local function getQboxAdapter(source)
    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        return QBCore.Functions.GetPlayer(source)
    end
    return exports.luxury_core:GetPlayer(source)
end

exports('GetQboxPlayer', getQboxAdapter)

exports('GetQboxPlayersData', function()
    local list = {}
    for src, _ in pairs(Core.Players) do
        local qp = getQboxAdapter(src)
        if qp and qp.PlayerData then
            list[#list + 1] = qp.PlayerData
        end
    end
    return list
end)

-- Notificaciones compatibles con lib.notify / qbx
RegisterNetEvent('qbx_core:client:notify', function(text, notifyType, duration)
    local msg = type(text) == 'table' and (text.description or text.title or '') or tostring(text or '')
    if Luxury and Luxury.Notify then
        Luxury.Notify(msg, notifyType or 'info', duration or 4000)
    elseif exports['luxury_notify'] then
        exports['luxury_notify']:Alert('Notificación', msg, duration or 4000, notifyType or 'info')
    end
end)
