-- luxury_lib: Utilidades matemáticas y sanitización estricta
Luxury = Luxury or {}
Luxury.Math = {}

--- Sanitiza y valida que un valor sea un número válido y seguro.
-- Previene exploits de Lua 5.4 como NaN, +/-Infinito, inyecciones de strings o desbordamientos.
-- @param value any: El valor a evaluar
-- @param min number|nil: Valor mínimo permitido (opcional)
-- @param max number|nil: Valor máximo permitido (opcional)
-- @param default number|nil: Valor retornado si la validación falla (por defecto 0)
-- @return number
function Luxury.Math.SanitizeNumber(value, min, max, default)
    default = default or 0
    if type(value) ~= 'number' and type(value) ~= 'string' then
        return default
    end

    local num = tonumber(value)

    -- Chequeo estricto de NaN (en Lua/IEEE-754: NaN ~= NaN) e Infinitos
    if not num or num ~= num or num == math.huge or num == -math.huge then
        return default
    end

    -- Truncar a entero seguro para evitar decimales no deseados en economía
    num = math.floor(num)

    if min and num < min then return min end
    if max and num > max then return max end

    return num
end

--- Redondea un número a una cantidad fija de decimales
-- @param num number
-- @param decimals number|nil
-- @return number
function Luxury.Math.Round(num, decimals)
    local n = tonumber(num)
    if not n or n ~= n or n == math.huge or n == -math.huge then return 0 end
    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end

--- Limita un valor numérico entre un mínimo y un máximo
-- @param value number
-- @param min number
-- @param max number
-- @return number
function Luxury.Math.Clamp(value, min, max)
    local num = tonumber(value) or min
    if num < min then return min end
    if num > max then return max end
    return num
end
