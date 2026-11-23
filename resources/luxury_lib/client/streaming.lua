-- luxury_lib: Streaming de modelos y animaciones con promesas y timeout
Luxury = Luxury or {}
Luxury.Streaming = {}

--- Solicita un modelo (vehículo, arma, objeto, ped) y espera a que esté cargado en memoria
-- @param model string|number: Nombre o hash del modelo
-- @param timeout number|nil: Tiempo máximo en ms (default 10000ms)
-- @return boolean: true si cargó correctamente, false si falló o timeout
function Luxury.Streaming.RequestModel(model, timeout)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        print(('[^1ERROR^7] luxury_lib: Modelo inválido %s'):format(tostring(model)))
        return false
    end

    if HasModelLoaded(hash) then return true end

    RequestModel(hash)
    local deadline = GetGameTimer() + (timeout or 10000)

    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then
            print(('[^1TIMEOUT^7] luxury_lib: Tiempo agotado cargando modelo %s'):format(tostring(model)))
            return false
        end
        Wait(10)
    end

    return true
end

--- Solicita un diccionario de animaciones y espera a que esté cargado
-- @param animDict string: Nombre del Animation Dictionary
-- @param timeout number|nil: Tiempo máximo en ms
-- @return boolean: true si cargó correctamente
function Luxury.Streaming.RequestAnimDict(animDict, timeout)
    if not DoesAnimDictExist(animDict) then
        print(('[^1ERROR^7] luxury_lib: Diccionario de animación no existe: %s'):format(animDict))
        return false
    end

    if HasAnimDictLoaded(animDict) then return true end

    RequestAnimDict(animDict)
    local deadline = GetGameTimer() + (timeout or 10000)

    while not HasAnimDictLoaded(animDict) do
        if GetGameTimer() > deadline then
            print(('[^1TIMEOUT^7] luxury_lib: Tiempo agotado cargando AnimDict: %s'):format(animDict))
            return false
        end
        Wait(10)
    end

    return true
end

--- Libera un modelo de la memoria de la GPU
-- @param model string|number
function Luxury.Streaming.ReleaseModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
    end
end

exports('RequestModel', Luxury.Streaming.RequestModel)
exports('RequestAnimDict', Luxury.Streaming.RequestAnimDict)
exports('ReleaseModel', Luxury.Streaming.ReleaseModel)
