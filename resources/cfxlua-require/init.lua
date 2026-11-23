--[[
    https://github.com/overextended/cfxlua-require

    This file is licensed under MPL-2.0 <https://www.mozilla.org/en-US/MPL/2.0/>

    Copyright © 2026 Linden <https://github.com/thelindat>
]]

if runtime?.require then return end

if package then
    warn('A module system is already initialised and will be overridden.')
end

runtime = runtime or {}
runtime.require = {
    author = GetResourceMetadata('require', 'author', 0),
    version = GetResourceMetadata('require', 'version', 0),
}

local type = type
local load = load
local pcall = pcall
local error = error
local assert = assert
local tostring = tostring
local LoadResourceFile = LoadResourceFile
local debug_getinfo = debug.getinfo
local table_concat = table.concat
local table_wipe = table.wipe
local sentinel = msgpack.sentinel()
local chunkName = debug_getinfo(1, 'S').source
local resourceName = GetCurrentResourceName()
local baseIdx = 2

for i = baseIdx, 32 do
    local src = debug_getinfo(i, 'S')?.short_src

    if not src or src == 'citizen:/scripting/lua/scheduler.lua' then
        baseIdx = i + 2
        break
    end
end

local lua_require = require

local function loadBuiltin(name) return lua_require(name) end

local package = {
    path = './?.lua;./?/init.lua',
    preload = {
        glm = loadBuiltin,
        lmprof = loadBuiltin,
    },
    loaded = {},
}

_ENV.package = package

local function getModuleInfo(modName)
    local resource, path = modName:match('^@(.-)/(.+)$')
    resource = resource or modName:match('^@(.+)$')

    if resource then
        return resource, path or 'init'
    end

    local idx = baseIdx

    while true do
        local src = debug_getinfo(idx, 'S')?.source

        if not src then
            return resourceName, modName
        end

        if src ~= chunkName then
            resource = src:match('^@@([^/]+)/.+')

            if resource then
                return resource, modName
            end
        end

        idx += 1
    end
end

local tempData = {}

function package.searchpath(name, path)
    local resource, modName = getModuleInfo(name:gsub('%.', '/'))
    local modulePath = modName:gsub('%.', '/')
    local tried = {}

    for template in path:gmatch('[^;]+') do
        local fileName = template:gsub('^%./', ''):gsub('%?', function() return modulePath end)
        local file = LoadResourceFile(resource, fileName)

        if file then
            tempData[1] = file
            tempData[2] = resource
            return fileName
        end

        tried[#tried + 1] = ("no file '@%s/%s'"):format(resource, fileName)
    end

    return nil, table_concat(tried, "\n\t")
end

local function loadModule(modName, env)
    local fileName, err = package.searchpath(modName, package.path)

    if fileName then
        local file = tempData[1]
        local resource = tempData[2]

        table_wipe(tempData)

        return assert(load(file, ('@@%s/%s'):format(resource, fileName), 't', env or _ENV)), fileName
    end

    return nil, err or 'unknown error'
end

package.searchers = {
    function(modName)
        if package.preload[modName] ~= nil then
            return package.preload[modName], ':preload:'
        end

        return nil, ("no field package.preload['%s']"):format(modName)
    end,
    function(modName) return loadModule(modName) end,
}

function require(modName)
    if type(modName) ~= 'string' then
        error(("module name must be a string (received '%s')"):format(modName), 3)
    end

    local module = package.loaded[modName]

    if module == sentinel then
        error(("circular-dependency occurred while loading module '%s'"):format(modName), 2)
    end

    if module ~= nil then return module end

    package.loaded[modName] = sentinel

    local err = {}

    for i = 1, #package.searchers do
        local loader, data = package.searchers[i](modName)

        if loader then
            local ok, result = pcall(loader, modName, data)

            if ok then
                if result ~= nil then
                    package.loaded[modName] = result
                elseif package.loaded[modName] == sentinel then
                    package.loaded[modName] = true
                end

                return package.loaded[modName], data
            end

            table.wipe(err)

            err[1] = ("an error occurred while loading module '%s'"):format(modName)
            err[2] = tostring(result)

            break
        end

        if data then err[#err + 1] = tostring(data) end
    end

    if package.loaded[modName] == sentinel then
        package.loaded[modName] = nil
    end

    table.insert(err, 1, ("module '%s' not found"):format(modName))

    error(("%s"):format(table_concat(err, "\n\t")), 2)
end

function loadfile(filePath, mode, env)
    if type(filePath) ~= 'string' then
        error(("file path must be a string (received '%s')"):format(filePath), 2)
    end

    local chunk, err = loadModule(filePath, env)

    if chunk then return chunk end

    error(("file '%s' not found\n\t%s"):format(filePath, err), 2)
end

function dofile(filePath)
    return loadfile(filePath)()
end

function json.load(filePath)
    if type(filePath) ~= 'string' then
        error(("file path must be a string (received '%s')"):format(filePath), 2)
    end

    local resource, modPath = getModuleInfo(filePath:gsub('%.', '/'))
    local fileName = ('%s.json'):format(modPath)
    local file = LoadResourceFile(resource, fileName)

    if not file then
        error(("json file '%s' not found\n\tno file '@%s/%s'"):format(filePath, resource, fileName), 2)
    end

    return json.decode(file)
end

return require
