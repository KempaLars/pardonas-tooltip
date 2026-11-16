-- Pardona's ToolTips - can the player character wear an item?
--
-- Preferred: the same signal the client shows. The item's tooltip lines are read with
-- C_TooltipInfo and the slot line (for example "Head  Plate") is checked for red text.
-- Other red lines (level requirement, class or profession lines) are not considered,
-- so the character level is ignored.
-- Fallback: a table class -> allowed armor and weapon types.
-- Returns true, false or nil (unknown). On nil no comparison is shown.

local _, ns = ...
local S = ns.Secret
local Items = ns.Items

local Wearable = {}
ns.Wearable = Wearable

---------------------------------------------------------------------------
-- Client tooltip check
---------------------------------------------------------------------------
local function IsRed(color)
    color = S.Table(color)
    if not color then return nil end
    local r, g, b = S.Number(S.Field(color, "r")), S.Number(S.Field(color, "g")), S.Number(S.Field(color, "b"))
    if not r or not g or not b then return nil end
    return r > 0.9 and g < 0.35 and b < 0.35
end

local function FromTooltip(link, equipLoc)
    if type(C_TooltipInfo) ~= "table" then return nil end
    local slotName = S.String(_G[equipLoc])
    if not slotName or slotName == "" then return nil end
    local data = S.Table(S.CallClean(C_TooltipInfo.GetHyperlink, link))
    local lines = data and S.Table(S.Field(data, "lines"))
    if not lines then return nil end
    for i = 1, #lines do
        local line = S.Table(lines[i])
        if line and S.String(S.Field(line, "leftText")) == slotName then
            local leftRed = IsRed(S.Field(line, "leftColor"))
            local rightRed = false
            if S.String(S.Field(line, "rightText")) then
                rightRed = IsRed(S.Field(line, "rightColor"))
            end
            if leftRed == nil or rightRed == nil then return nil end
            return not (leftRed or rightRed)
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Fallback table (Enum names, resolved at runtime)
---------------------------------------------------------------------------
local ALL_ARMOR = { "Generic", "Cloth", "Cosmetic" }

local ARMOR = {
    WARRIOR = { "Leather", "Mail", "Plate", "Shield" },
    PALADIN = { "Leather", "Mail", "Plate", "Shield", "Libram" },
    HUNTER  = { "Leather", "Mail" },
    ROGUE   = { "Leather" },
    PRIEST  = {},
    SHAMAN  = { "Leather", "Mail", "Shield", "Totem" },
    MAGE    = {},
    WARLOCK = {},
    DRUID   = { "Leather", "Idol" },
}

local ALL_WEAPONS = { "Generic", "Fishingpole" }

local WEAPONS = {
    WARRIOR = { "Axe1H", "Axe2H", "Bows", "Guns", "Mace1H", "Mace2H", "Polearm", "Sword1H",
                "Sword2H", "Staff", "Unarmed", "Dagger", "Thrown", "Crossbow" },
    PALADIN = { "Axe1H", "Axe2H", "Mace1H", "Mace2H", "Polearm", "Sword1H", "Sword2H" },
    HUNTER  = { "Axe1H", "Axe2H", "Bows", "Guns", "Polearm", "Sword1H", "Sword2H", "Staff",
                "Unarmed", "Dagger", "Thrown", "Crossbow" },
    ROGUE   = { "Bows", "Guns", "Mace1H", "Sword1H", "Unarmed", "Dagger", "Thrown", "Crossbow" },
    PRIEST  = { "Mace1H", "Staff", "Dagger", "Wand" },
    SHAMAN  = { "Axe1H", "Axe2H", "Mace1H", "Mace2H", "Staff", "Unarmed", "Dagger" },
    MAGE    = { "Sword1H", "Staff", "Dagger", "Wand" },
    WARLOCK = { "Sword1H", "Staff", "Dagger", "Wand" },
    DRUID   = { "Mace1H", "Mace2H", "Staff", "Unarmed", "Dagger" },
}

local function Contains(enumTable, names, subclassID)
    for i = 1, #names do
        if S.Number(S.Field(enumTable, names[i])) == subclassID then return true end
    end
    return false
end

local function FromTable(link)
    local _, _, classID, subclassID = Items.Instant(link)
    if not classID or not subclassID then return nil end
    local enum = S.Table(Enum)
    local itemClass = enum and S.Table(enum.ItemClass)
    if not itemClass then return nil end
    local _, classFile = ns.Units.Class("player")
    if not classFile then return nil end

    if classID == S.Number(S.Field(itemClass, "Armor")) then
        local subclasses = S.Table(enum.ItemArmorSubclass)
        local allowed = ARMOR[classFile]
        if not subclasses or not allowed then return nil end
        return Contains(subclasses, ALL_ARMOR, subclassID) or Contains(subclasses, allowed, subclassID)
    elseif classID == S.Number(S.Field(itemClass, "Weapon")) then
        local subclasses = S.Table(enum.ItemWeaponSubclass)
        local allowed = WEAPONS[classFile]
        if not subclasses or not allowed then return nil end
        return Contains(subclasses, ALL_WEAPONS, subclassID) or Contains(subclasses, allowed, subclassID)
    end
    return nil
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function Wearable.Check(link)
    local _, equipLoc = Items.Instant(link)
    if not equipLoc then return nil end
    local result = FromTooltip(link, equipLoc)
    if result ~= nil then return result end
    return FromTable(link)
end
