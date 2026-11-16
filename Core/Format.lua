-- Pardona's ToolTips - number formatting for visible texts.
-- Separators and formats come from the locale files, so numbers follow the client
-- language (enUS 1,234.5 / deDE 1.234,5). Callers must never pass secret values.

local _, ns = ...
local L = ns.L

local Format = {}
ns.Format = Format

local floor, tostring, concat = math.floor, tostring, table.concat

-- Whole number with thousands separators, for example 12345 -> "12,345" (enUS).
function Format.Number(n)
    n = floor(n + 0.5)
    local negative = n < 0
    local digits = tostring(negative and -n or n)
    local first = #digits % 3
    if first == 0 then first = 3 end
    local parts = { digits:sub(1, first) }
    for i = first + 1, #digits, 3 do
        parts[#parts + 1] = digits:sub(i, i + 2)
    end
    local text = concat(parts, L.THOUSANDS_SEPARATOR)
    return negative and ("-" .. text) or text
end

-- Number with a fixed count of decimal places and the locale's decimal separator.
function Format.Decimal(n, places)
    local text = ("%." .. places .. "f"):format(n)
    local whole, fraction = text:match("^(-?%d+)%.(%d+)$")
    if not whole then return text end
    return Format.Number(tonumber(whole)) .. L.DECIMAL_SEPARATOR .. fraction
end

-- Whole percentage, for example 62 -> "62%" (enUS) or "62 %" (deDE).
function Format.Percent(p)
    return L.PERCENT_FORMAT:format(floor(p + 0.5))
end

-- Percentage text for a secret value (0-100). The game lets string.format turn a secret
-- number into a secret string that only its widgets can show (SetText). Returns nil when
-- that is not possible; the caller then leaves the text out. The result must never be
-- compared, measured or concatenated.
function Format.SecretPercent(value)
    local ok, text = pcall(string.format, L.PERCENT_SECRET_FORMAT, value)
    if not ok then return nil end
    return text
end

-- Chance in percent: whole numbers like Percent, otherwise one decimal ("99.5%").
function Format.Chance(p)
    if p == floor(p) then return Format.Percent(p) end
    return L.PERCENT_DECIMAL_FORMAT:format(Format.Decimal(p, 1))
end

-- "current / max" with thousands separators.
function Format.Ratio(current, max)
    return L.RATIO_FORMAT:format(Format.Number(current), Format.Number(max))
end
