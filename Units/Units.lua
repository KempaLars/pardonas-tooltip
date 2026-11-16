-- Pardona's ToolTips - secret-safe unit helpers shared by all unit features.
-- Every function returns nil when the game hides the answer (secret value, missing
-- API or error). Callers then leave the affected line out.

local _, ns = ...
local S = ns.Secret
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
-- Results come in three grades, matching what the game lets addons read:
--   "exact",   current, max   both numbers readable (max > 0)
--   "percent", percent        only the percentage (0-100) is readable
--   "secret",  value          the percentage is a secret value (0-100); it may only be
--                             passed on to the game (string.format, SetText), never
--                             compared or calculated
-- nil means nothing to show (unit gone, no resource, maximum 0, API missing).
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

local function Graded(current, max, percentFn, ...)
    if current and max then
        if max <= 0 then return nil end
        return "exact", current, max
    end
    if max and max <= 0 then return nil end
    local percent = PercentCall(percentFn, ...)
    if percent == nil then return nil end
    if S.IsSecret(percent) then return "secret", percent end
    return "percent", percent
end

-- Raw result of UnitHealthPercent (0-100; may be secret), for diagnostics.
function Units.HealthPercentRaw(unit)
    return PercentCall(UnitHealthPercent, unit, false)
end

-- Raw result of UnitPowerPercent (0-100; may be secret), for diagnostics.
function Units.PowerPercentRaw(unit, powerType)
    return PercentCall(UnitPowerPercent, unit, powerType, false)
end

-- Health of unit as grade, value(s); see above.
function Units.Health(unit)
    local current = S.Number(S.CallClean(UnitHealth, unit))
    local max = S.Number(S.CallClean(UnitHealthMax, unit))
    return Graded(current, max, UnitHealthPercent, unit, false)
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

-- Main resource of unit: grade, value(s), localized name; see above. nil when the unit
-- has no resource, its maximum is 0 or its name is unknown.
function Units.Power(unit)
    local powerType, _, name = Units.PowerType(unit)
    if not powerType or not name or name == "" then return nil end
    local current = S.Number(S.CallClean(UnitPower, unit, powerType))
    local max = S.Number(S.CallClean(UnitPowerMax, unit, powerType))
    local grade, a, b = Graded(current, max, UnitPowerPercent, unit, powerType, false)
    if not grade then return nil end
    return grade, a, b, name
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
