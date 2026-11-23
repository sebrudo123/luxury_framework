-- luxury_lib: Utilidades para manejo seguro de tablas
Luxury = Luxury or {}
Luxury.Table = {}

--- Clona una tabla de forma profunda (Deep Copy)
-- @param orig table
-- @return table
function Luxury.Table.Clone(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Luxury.Table.Clone(orig_key)] = Luxury.Table.Clone(orig_value)
        end
        setmetatable(copy, Luxury.Table.Clone(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Comprueba si una tabla contiene un valor determinado
-- @param tbl table
-- @param target any
-- @return boolean, any (true y la clave si existe, false si no)
function Luxury.Table.Contains(tbl, target)
    if type(tbl) ~= 'table' then return false end
    for k, v in pairs(tbl) do
        if v == target then return true, k end
    end
    return false
end

--- Obtiene la cantidad de elementos en una tabla (incluyendo claves no numéricas)
-- @param tbl table
-- @return number
function Luxury.Table.Size(tbl)
    local count = 0
    if type(tbl) ~= 'table' then return count end
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
