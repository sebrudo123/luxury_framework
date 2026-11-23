-- luxury_core: Estado y Datos del Jugador Local (Client Player)
PlayerData = PlayerData or {}

--- Retorna la tabla de datos completa del jugador local
-- @return table
function GetPlayerData()
    return PlayerData
end

--- Comprueba si el jugador local ha completado la carga y el spawn
-- @return boolean
function IsPlayerLoaded()
    return LocalPlayer.state.isLoggedIn or false
end

--- Obtiene el trabajo actual del jugador
-- @return table
function GetPlayerJob()
    return PlayerData.job or { name = 'unemployed', grade = 0 }
end

--- Obtiene la banda actual del jugador
-- @return table
function GetPlayerGang()
    return PlayerData.gang or { name = 'none', grade = 0 }
end

-- Exports del cliente
exports('GetPlayerData', GetPlayerData)
exports('IsPlayerLoaded', IsPlayerLoaded)
exports('GetPlayerJob', GetPlayerJob)
exports('GetPlayerGang', GetPlayerGang)
