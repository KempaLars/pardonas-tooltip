-- Pardona's ToolTips - secret-safe unit helpers shared by all unit features.
-- Every function returns nil when the game hides the answer (secret value, missing
-- API or error). Callers then leave the affected line out.

local _, ns = ...
local L = ns.L
local S = ns.Secret
local Format = ns.Format
local ColorSets = ns.ColorSets

local Units = {}
ns.Units = Units

-- Unit token of a unit tooltip. Uses the token from the tooltip when it is not secret.
-- Otherwise "mouseover" is used, but only for GameTooltip and only when its GUID
-- provably matches the tooltip data; if that cannot be checked, nil is returned.
function Units.Resolve(tooltip, data)
    local _, unit = S.Method(tooltip, "GetUnit")
    unit = S.String(unit)
    if unit then return unit end

    if S.IsSecret(tooltip) or tooltip ~= GameTooltip then return nil end
    local dataGUID = S.String(S.Field(data, "guid"))
    local mouseoverGUID = Units.GUID("mouseover")
    if dataGUID and mouseoverGUID and dataGUID == mouseoverGUID then
        return "mouseover"
    end
    return nil
end

-- true when both tokens point to the same unit, false when not, nil when unknown.
-- C_Secrets.CanCompareUnitTokens (if present) decides first whether the game allows the
-- comparison at all; UnitIsUnit's answer is only used when it is not secret.
function Units.IsSameUnit(a, b)
    local secrets = S.Table(C_Secrets)
    if secrets and type(secrets.CanCompareUnitTokens) == "function" then
        if S.Boolean(S.CallClean(secrets.CanCompareUnitTokens, a, b)) == false then
            return nil
        end
    end
    return S.Boolean(S.CallClean(UnitIsUnit, a, b))
end

-- "target" when unit is also the player's target, otherwise unit itself. The target
-- token is often readable in more detail than "mouseover".
function Units.PreferTarget(unit)
    if not unit or unit == "target" then return unit end
    if Units.IsSameUnit(unit, "target") == true then return "target" end
    return unit
end

function Units.GUID(unit)
    return S.String(S.CallClean(UnitGUID, unit))
end

function Units.Exists(unit)
    return S.Boolean(S.CallClean(UnitExists, unit))
end

function Units.IsPlayer(unit)
    return S.Boolean(S.CallClean(UnitIsPlayer, unit))
end

-- true when unit is the player character, false when not, nil when unknown.
function Units.IsSelf(unit)
    return S.Boolean(S.CallClean(UnitIsUnit, unit, "player"))
end

function Units.Name(unit)
    return S.String(S.CallClean(UnitName, unit))
end

-- Localized class name and class file (for example "Mage", "MAGE").
function Units.Class(unit)
    local className, classFile = S.CallClean(UnitClass, unit)
    return S.String(className), S.String(classFile)
end

-- Reaction of unit towards the player (1..8) or nil.
function Units.Reaction(unit)
    return S.Number(S.CallClean(UnitReaction, unit, "player"))
end

-- { r, g, b } of a class file or nil.
function Units.ClassColor(classFile)
    if not classFile then return nil end
    local color
    if type(C_ClassColor) == "table" then
        color = ColorSets.FromColorTable(S.CallClean(C_ClassColor.GetClassColor, classFile))
    end
    if not color then
        local colors = S.Table(RAID_CLASS_COLORS)
        color = colors and ColorSets.FromColorTable(colors[classFile]) or nil
    end
    return color
end

-- { r, g, b } for a reaction value: hostile, neutral or friendly.
function Units.ReactionColor(reaction)
    if not reaction then return nil end
    if reaction <= 3 then
        return ColorSets.REACTION.hostile
    elseif reaction == 4 then
        return ColorSets.REACTION.neutral
    end
    return ColorSets.REACTION.friendly
end

-- Players in class color, everything else in reaction color; nil when unknown.
function Units.Color(unit)
    local isPlayer = Units.IsPlayer(unit)
    if isPlayer == nil then return nil end
    if isPlayer then
        local _, classFile = Units.Class(unit)
        return Units.ClassColor(classFile)
    end
    return Units.ReactionColor(Units.Reaction(unit))
end

---------------------------------------------------------------------------
-- Health and power
--
-- Readings come in three parts, matching what the game lets addons read:
--   current  raw value; may be a secret value. A secret current value is only ever
--            passed on to the game (string.format, StatusBar:SetValue, SetText), never
--            compared or calculated.
--   max      clean number or nil (nil when secret or missing)
--   percent  only fetched when current is not readable: a clean number (0-100), a
--            secret value (0-100) or nil
---------------------------------------------------------------------------

-- Curve that makes the percent APIs return 0-100 instead of 0-1 (nil when missing).
local function ScaleTo100()
    local curves = S.Table(CurveConstants)
    return curves and curves.ScaleTo100
end

-- Calls a percent API (UnitHealthPercent/UnitPowerPercent). Returns a clean number
-- (0-100), a secret value (0-100) or nil. The result may be secret on purpose.
local function PercentCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local curve = ScaleTo100()
    if curve ~= nil then
        local args = { ... }
        args[#args + 1] = curve
        local value = S.Call(fn, unpack(args))
        if value == nil then return nil end
        if S.IsSecret(value) then return value end
        return type(value) == "number" and value or nil
    end
    -- Without the curve the API returns 0-1; scaling needs a clean value.
    local value = S.Number(S.Call(fn, ...))
    return value and value * 100 or nil
end

-- Raw result of UnitHealthPercent (0-100; may be secret), for diagnostics.
function Units.HealthPercentRaw(unit)
    return PercentCall(UnitHealthPercent, unit, false)
end

-- Raw result of UnitPowerPercent (0-100; may be secret), for diagnostics.
function Units.PowerPercentRaw(unit, powerType)
    return PercentCall(UnitPowerPercent, unit, powerType, false)
end

-- Text of a whole number that may be secret, with thousands separators when possible.
-- Clean numbers use Format.Number. Secret numbers first try Blizzard's
-- BreakUpLargeNumbers (read through _G, may be missing or refuse secret values), then
-- string.format("%d"). Returns text, ok; the text may be a secret string.
local function NumberText(value)
    local clean = S.Number(value)
    if clean then return Format.Number(clean), true end
    if not S.IsSecret(value) then return nil, false end
    local breakUp = _G.BreakUpLargeNumbers
    if type(breakUp) == "function" then
        local ok, text = pcall(breakUp, value)
        -- Only accept a string (secret or clean); type() is not used on secret values.
        if ok and (S.IsSecret(text) or type(text) == "string") then return text, true end
    end
    local ok, text = pcall(string.format, "%d", value)
    if ok then return text, true end
    return nil, false
end

-- Text "current / max (percent)" for a reading, for example "812 / 1,025 (79%)".
-- Grades, best first:
--   current and max readable          ratio and our own percentage
--   current secret, max readable      ratio with the secret current value and the
--                                     percent API (clean or secret)
--   ratio impossible                  percentage only (clean or secret)
--   nothing usable                    nil
-- Returns text, hasText. The text may be a secret string: it may only go to our own
-- widgets (SetText), and callers test hasText instead of comparing the text.
-- percentFn and its arguments (without the curve) are used when current is not clean.
function Units.ValueText(current, max, percentFn, ...)
    if max and max <= 0 then return nil, false end
    local cleanCurrent = S.Number(current)

    local percentText, hasPercent
    if cleanCurrent and max then
        percentText, hasPercent = Format.Percent(cleanCurrent / max * 100), true
    else
        local percent = PercentCall(percentFn, ...)
        if S.IsSecret(percent) then
            percentText = Format.SecretPercent(percent)
            hasPercent = S.IsSecret(percentText) or type(percentText) == "string"
        elseif type(percent) == "number" then
            percentText, hasPercent = Format.Percent(percent), true
        end
    end

    if max then
        local currentText, hasCurrent = NumberText(current)
        if hasCurrent then
            local ok, ratio = pcall(string.format, L.RATIO_FORMAT, currentText, Format.Number(max))
            if ok then
                if not hasPercent then return ratio, true end
                local ok2, text = pcall(string.format, L.VALUE_FORMAT, ratio, percentText)
                if ok2 then return text, true end
            end
        end
    end
    if hasPercent then return percentText, true end
    return nil, false
end

-- Health of unit: current (raw, may be secret), max (clean or nil).
function Units.HealthValues(unit)
    local current = S.Call(UnitHealth, unit)
    local max = S.Number(S.CallClean(UnitHealthMax, unit))
    return current, max
end

-- Health text of unit (see Units.ValueText); nil when nothing can be shown.
function Units.HealthText(unit)
    local current, max = Units.HealthValues(unit)
    return Units.ValueText(current, max, UnitHealthPercent, unit, false)
end

-- Global string key of a power type from Enum.PowerType, for example "RunicPower" ->
-- "RUNIC_POWER"; used when UnitPowerType returns no token.
local function PowerTokenFromEnum(powerType)
    local types = S.Table(Enum) and S.Table(Enum.PowerType)
    if not types then return nil end
    for name, value in pairs(types) do
        if value == powerType and type(name) == "string" then
            return (name:gsub("(%l)(%u)", "%1_%2")):upper()
        end
    end
    return nil
end

-- Main power type of unit: number, token ("MANA") and the localized name from Blizzard's
-- global strings (MANA, RAGE, ENERGY, FOCUS, ...). nil when unknown.
function Units.PowerType(unit)
    local powerType, token = S.Call(UnitPowerType, unit)
    powerType, token = S.Number(powerType), S.String(token)
    if not powerType then return nil end
    token = token or PowerTokenFromEnum(powerType)
    local name = token and S.String(_G[token])
    return powerType, token, name
end

-- Main resource of unit: powerType, token, current (raw, may be secret), max (clean or
-- nil). nil when the power type is unknown.
function Units.PowerValues(unit)
    local powerType, token = Units.PowerType(unit)
    if not powerType then return nil end
    local current = S.Call(UnitPower, unit, powerType)
    local max = S.Number(S.CallClean(UnitPowerMax, unit, powerType))
    return powerType, token, current, max
end

-- Text of the main resource (see Units.ValueText) for a known power type.
function Units.PowerText(unit, powerType, current, max)
    return Units.ValueText(current, max, UnitPowerPercent, unit, powerType, false)
end

---------------------------------------------------------------------------
-- Tooltip line access
---------------------------------------------------------------------------

-- Number of lines in tooltip, 0 when unknown.
function Units.NumLines(tooltip)
    return S.Number(S.Method(tooltip, "NumLines")) or 0
end

-- Font string of a tooltip line; side is "Left" or "Right".
function Units.Line(tooltip, side, index)
    local name = S.String(S.Method(tooltip, "GetName"))
    if not name then return nil end
    local fontString = _G[name .. "Text" .. side .. index]
    if fontString == nil or S.IsSecret(fontString) then return nil end
    return fontString
end

-- Appends "label  value" in the set's label color; value color defaults to the set's
-- value color. Returns the index of the new line (0 when unknown).
function Units.AddPair(tooltip, label, value, valueColor)
    local lr, lg, lb = ColorSets.TextColor("label")
    local vr, vg, vb
    if valueColor then
        vr, vg, vb = valueColor[1], valueColor[2], valueColor[3]
    else
        vr, vg, vb = ColorSets.TextColor("value")
    end
    S.Method(tooltip, "AddDoubleLine", label, value, lr, lg, lb, vr, vg, vb)
    return Units.NumLines(tooltip)
end

-- Appends a single line in the color of a text role of the current set.
function Units.AddRoleLine(tooltip, text, role)
    local r, g, b = ColorSets.TextColor(role)
    S.Method(tooltip, "AddLine", text, r, g, b)
end

-- Text of a font string, nil when empty or secret.
function Units.LineText(fontString)
    if not fontString then return nil end
    return S.String(S.Method(fontString, "GetText"))
end
