-- Pardona's ToolTips - prices from TradeSkillMaster (optional) and money formatting.
--
-- Only TSM's public API is used: TSM_API.ToItemString, TSM_API.GetCustomPriceValue and
-- TSM_API.FormatMoneyString. Every call is protected; nil means "no data".
-- TSM_API is read through _G because TradeSkillMaster is an optional dependency.

local _, ns = ...
local S = ns.Secret
local Format = ns.Format

local Prices = {}
ns.Prices = Prices

local function API()
    local api = _G.TSM_API
    if type(api) ~= "table" then return nil end
    if type(api.ToItemString) ~= "function" or type(api.GetCustomPriceValue) ~= "function" then
        return nil
    end
    return api
end

-- True when TradeSkillMaster's public API is available.
function Prices.Available()
    return API() ~= nil
end

-- TSM item string for a link, or nil.
function Prices.ItemString(link)
    local api = API()
    if not api or not link then return nil end
    local ok, itemString = pcall(api.ToItemString, link)
    if not ok then return nil end
    return S.String(itemString)
end

-- Value of a TSM price source (copper or a plain number), or nil.
function Prices.Value(source, itemString)
    local api = API()
    if not api or not itemString then return nil end
    local ok, value = pcall(api.GetCustomPriceValue, source, itemString)
    if not ok then return nil end
    value = S.Number(value)
    if value and value ~= value then return nil end -- NaN
    return value
end

-- Non-money key figure of a TSM source (for example DBRegionSaleRate), or nil.
--
-- TSM rounds every custom price result to a whole number, so a sale rate of 0.737 would
-- come back as 1. The source is therefore requested as an expression scaled by `scale`
-- (TSM's own tooltip does the same with "DBRegionSaleRate * 1000"). "+ 1" keeps a real 0
-- apart from "no data": TSM returns nil for a result of 0, and a missing source makes
-- the whole expression invalid (nil), so 0 arrives as 1 and missing data stays nil.
function Prices.Metric(source, scale, itemString)
    local value = Prices.Value(("%s * %d + 1"):format(source, scale), itemString)
    if not value then return nil end
    return (value - 1) / scale
end

---------------------------------------------------------------------------
-- Money
---------------------------------------------------------------------------
local GOLD_ICON   = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

local function OwnMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper / 100) % 100
    local rest = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = Format.Number(gold) .. GOLD_ICON end
    if silver > 0 or gold > 0 then parts[#parts + 1] = silver .. SILVER_ICON end
    parts[#parts + 1] = rest .. COPPER_ICON
    return table.concat(parts, " ")
end

-- Money text for a copper value: TSM's format if available, otherwise gold/silver/copper icons.
function Prices.Money(copper)
    copper = math.floor(copper + 0.5)
    if copper < 0 then copper = 0 end
    local api = _G.TSM_API
    if type(api) == "table" and type(api.FormatMoneyString) == "function" then
        local ok, text = pcall(api.FormatMoneyString, copper)
        text = ok and S.String(text) or nil
        if text and text ~= "" then return text end
    end
    return OwnMoney(copper)
end
