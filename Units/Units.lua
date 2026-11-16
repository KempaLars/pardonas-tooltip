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
