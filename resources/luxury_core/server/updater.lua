-- ====================================================================
-- LUXURY FRAMEWORK - SISTEMA DE DETECCIÓN Y AUTO-UPDATER PARA TXADMIN
-- Comprueba actualizaciones en GitHub y permite actualizar en vivo
-- ====================================================================

local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.3.0'
local githubRepo = 'sebrudo123/luxury_framework'
local branch = 'main'
local versionUrl = ('https://raw.githubusercontent.com/%s/%s/version.json'):format(githubRepo, branch)
local baseUrl = ('https://raw.githubusercontent.com/%s/%s/'):format(githubRepo, branch)

local isUpdating = false
local latestVersionData = nil

-- Función para comparar versiones semánticas (ej. 1.2.0 < 1.3.0)
local function isVersionNewer(current, latest)
    local function parseVersion(v)
        local parts = {}
        for num in string.gmatch(tostring(v):gsub('v', ''), '%d+') do
            table.insert(parts, tonumber(num))
        end
        return parts
    end

    local cParts = parseVersion(current)
    local lParts = parseVersion(latest)

    for i = 1, math.max(#cParts, #lParts) do
        local c = cParts[i] or 0
        local l = lParts[i] or 0
        if l > c then return true end
        if l < c then return false end
    end
    return false
end

-- Comprobación de versión en GitHub
local function checkForUpdates(silent)
    PerformHttpRequest(versionUrl, function(status, responseText, headers)
        if status ~= 200 or not responseText then
            if not silent then
                print('^1[LUXURY-UPDATER] No se pudo conectar a GitHub para verificar actualizaciones (HTTP ' .. tostring(status) .. ').^0')
            end
            return
        end

        local data = json.decode(responseText)
        if not data or not data.version then return end
        latestVersionData = data

        if isVersionNewer(currentVersion, data.version) then
            print('^3====================================================================^0')
            print('^2[LUXURY-UPDATER] ¡NUEVA ACTUALIZACIÓN DISPONIBLE EN GITHUB!^0')
            print(('^7Versión instalada: ^1v%s^7  ->  Última versión disponible: ^2v%s^0'):format(currentVersion, data.version))
            if data.changelog then
                print(('^6Novedades: ^7%s^0'):format(data.changelog))
            end
            print('^3Para actualizar automáticamente sin reinstalar, ejecuta en txAdmin:^0')
            print('^2luxury_update^0')
            print('^3====================================================================^0')
        else
            if not silent then
                print(('^2[LUXURY-UPDATER] Luxury Framework está al día en la versión más reciente (v%s).^0'):format(currentVersion))
            end
        end
    end, 'GET', '', { ['User-Agent'] = 'FXServer-LuxuryUpdater' })
end

-- Ejecución automática al arrancar el servidor
CreateThread(function()
    Wait(4000) -- Esperar a que la consola inicial de FXServer y txAdmin se asiente
    checkForUpdates(false)

    -- Verificación periódica en segundo plano cada 30 minutos
    while true do
        Wait(30 * 60 * 1000)
        checkForUpdates(true)
    end
end)

-- Comando: luxury_check (Verificar manualmente)
RegisterCommand('luxury_check', function(source)
    if source == 0 then
        print('^3[LUXURY-UPDATER] Consultando el repositorio oficial en GitHub...^0')
        checkForUpdates(false)
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = { 212, 175, 55 },
            args = { 'LUXURY', 'Comando reservado para la consola del servidor txAdmin.' }
        })
    end
end, true)

-- Lógica de Actualización de Archivos
local function saveUpdateFile(resName, filePath, content)
    -- 1. Intentar con SaveResourceFile nativo de FXServer
    local ok = SaveResourceFile(resName, filePath, content, -1)
    if ok then
        -- También guardar réplica en bridges dentro de luxury_core si es recurso puente
        if resName ~= GetCurrentResourceName() then
            SaveResourceFile(GetCurrentResourceName(), 'bridges/' .. resName .. '/' .. filePath, content, -1)
        end
        return true
    end

    -- 2. Si el recurso aún no estaba cargado por FXServer, escribir en el sistema de archivos
    local corePath = GetResourcePath(GetCurrentResourceName())
    if corePath then
        local parentDir = corePath:match('^(.*)[/\\][^/\\]+$')
        if parentDir then
            local targetPath = parentDir .. '/' .. resName .. '/' .. filePath
            local f = io.open(targetPath, 'w+b')
            if f then
                f:write(content)
                f:close()
                if resName ~= GetCurrentResourceName() then
                    SaveResourceFile(GetCurrentResourceName(), 'bridges/' .. resName .. '/' .. filePath, content, -1)
                end
                return true
            end
        end
    end

    -- 3. Respaldo garantizado dentro de luxury_core
    if resName ~= GetCurrentResourceName() then
        return SaveResourceFile(GetCurrentResourceName(), 'bridges/' .. resName .. '/' .. filePath, content, -1)
    end

    return false
end

local function performUpdateProcess()
    if isUpdating then
        print('^1[LUXURY-UPDATER] Ya hay un proceso de actualización en curso.^0')
        return
    end

    isUpdating = true
    print('^3====================================================================^0')
    print('^3[LUXURY-UPDATER] INICIANDO ACTUALIZACIÓN AUTOMÁTICA EN VIVO...^0')
    print('^3[LUXURY-UPDATER] Descargando manifiesto de archivos desde GitHub...^0')

    PerformHttpRequest(versionUrl, function(status, responseText)
        if status ~= 200 or not responseText then
            print('^1[LUXURY-UPDATER] Error al descargar lista de archivos de GitHub (HTTP ' .. tostring(status) .. '). Abortando.^0')
            isUpdating = false
            return
        end

        local data = json.decode(responseText)
        if not data or not data.files then
            print('^1[LUXURY-UPDATER] Manifiesto inválido o corrupto. Abortando.^0')
            isUpdating = false
            return
        end

        local filesToUpdate = {}
        for resName, fileList in pairs(data.files) do
            for _, fPath in ipairs(fileList) do
                table.insert(filesToUpdate, {
                    resource = resName,
                    path = fPath,
                    url = baseUrl .. 'resources/' .. resName .. '/' .. fPath
                })
            end
        end

        local totalFiles = #filesToUpdate
        local completed = 0
        local errors = 0

        print(('^3[LUXURY-UPDATER] Descargando e instalando %d archivos actualizados (cfxlua-require, bridges y scripts)...^0'):format(totalFiles))

        for _, fileInfo in ipairs(filesToUpdate) do
            PerformHttpRequest(fileInfo.url, function(fStatus, fContent)
                if fStatus == 200 and fContent and #fContent > 0 then
                    local saveSuccess = saveUpdateFile(fileInfo.resource, fileInfo.path, fContent)
                    if saveSuccess then
                        print(('^2[ACTUALIZADO]^0 %s/%s'):format(fileInfo.resource, fileInfo.path))
                    else
                        print(('^3[AVISO]^0 %s/%s guardado localmente.'):format(fileInfo.resource, fileInfo.path))
                    end
                else
                    print(('^1[ERROR]^0 Fallo al descargar: %s/%s (HTTP %s)'):format(fileInfo.resource, fileInfo.path, tostring(fStatus)))
                    errors = errors + 1
                end

                completed = completed + 1

                if completed == totalFiles then
                    isUpdating = false
                    print('^3====================================================================^0')
                    if errors == 0 then
                        print(('^2[LUXURY-UPDATER] ¡Todos los archivos fueron actualizados exitosamente a v%s!^0'):format(data.version or 'Nueva'))
                    else
                        print(('^3[LUXURY-UPDATER] Proceso completado con %d advertencias no críticas.^0'):format(errors))
                    end
                    print('^2[LUXURY-UPDATER] Recargando y asegurando recursos (cfxlua-require, require, core, hud...)...^0')
                    print('^3====================================================================^0')

                    -- Recargar lista de recursos y reiniciar en orden estricto de arranque
                    ExecuteCommand('refresh')
                    Wait(600)
                    ExecuteCommand('ensure cfxlua-require')
                    ExecuteCommand('ensure require')
                    Wait(300)
                    ExecuteCommand('restart luxury_lib')
                    Wait(300)
                    ExecuteCommand('restart luxury_core')
                    Wait(300)
                    ExecuteCommand('ensure es_extended')
                    ExecuteCommand('restart es_extended')
                    ExecuteCommand('ensure qb-core')
                    ExecuteCommand('restart qb-core')
                    ExecuteCommand('ensure qbx_core')
                    ExecuteCommand('restart qbx_core')
                    ExecuteCommand('restart luxury_hud')
                    ExecuteCommand('restart luxury_banking')
                    ExecuteCommand('restart luxury_garage')
                    ExecuteCommand('restart luxury_radial')
                    ExecuteCommand('restart luxury_multicharacter')

                    print('^2[LUXURY-UPDATER] ¡Actualización en vivo finalizada con éxito! Todos los recursos al día.^0')
                end
            end, 'GET', '', { ['User-Agent'] = 'FXServer-LuxuryUpdater' })
            Wait(25)
        end
    end, 'GET', '', { ['User-Agent'] = 'FXServer-LuxuryUpdater' })
end

-- Comando Principal: luxury_update (Consola de txAdmin)
RegisterCommand('luxury_update', function(source)
    if source == 0 then
        performUpdateProcess()
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 50, 50 },
            args = { 'LUXURY', 'El comando luxury_update solo puede ejecutarse desde la consola de txAdmin.' }
        })
    end
end, true)

-- Alias alternativo: luxury:update
RegisterCommand('luxury:update', function(source)
    if source == 0 then
        performUpdateProcess()
    end
end, true)

-- Exports públicos
exports('CheckForUpdates', function() checkForUpdates(false) end)
exports('UpdateFramework', function() performUpdateProcess() end)
