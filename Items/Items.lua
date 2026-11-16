-- Pardona's ToolTips - secret-safe item helpers shared by the item features.
-- Every function returns nil when the game hides the answer (secret value, missing API
-- or error); callers then leave the affected line out.

local _, ns = ...
local S = ns.Secret
local ColorSets = ns.ColorSets

local Items = {}
ns.Items = Items

-- Equipment slots (inventory slot IDs).
Items.SLOT = {
    HEAD = 1, NECK = 2, SHOULDER = 3, CHEST = 5, WAIST = 6, LEGS = 7, FEET = 8,
    WRIST = 9, HANDS = 10, FINGER1 = 11, FINGER2 = 12, TRINKET1 = 13, TRINKET2 = 14,
    BACK = 15, MAIN_HAND = 16, OFF_HAND = 17, RANGED = 18,
}

-- Equip locations that count as equipment (shirt, tabard, bags and ammo do not).
local EQUIPMENT = {
    INVTYPE_HEAD = true, INVTYPE_NECK = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true,
    INVTYPE_ROBE = true, INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true,
    INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_FINGER = true, INVTYPE_TRINKET = true,
    INVTYPE_CLOAK = true, INVTYPE_WEAPON = true, INVTYPE_SHIELD = true, INVTYPE_2HWEAPON = true,
    INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_HOLDABLE = true,
    INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true, INVTYPE_RELIC = true,
}

-- Item link of an item tooltip: from the tooltip, else from the tooltip data.
function Items.LinkFromTooltip(tooltip, data)
    local _, link = S.Method(tooltip, "GetItem")
    link = S.String(link)
    if link and link ~= "" then return link end
    link = S.String(S.Field(data, "hyperlink"))
    if link and link ~= "" then return link end
    return nil
end

-- itemID, equipLoc, classID, subclassID of an item link (each may be nil).
function Items.Instant(link)
    if not link or type(C_Item) ~= "table" then return nil end
    local itemID, _, _, equipLoc, _, classID, subclassID = S.CallClean(C_Item.GetItemInfoInstant, link)
    return S.Number(itemID), S.String(equipLoc), S.Number(classID), S.Number(subclassID)
end

-- True when link is a piece of equipment (weapon, armor, jewelry, shield, off-hand).
function Items.IsEquipment(link)
    local _, equipLoc = Items.Instant(link)
    return equipLoc ~= nil and EQUIPMENT[equipLoc] == true
end

-- Effective item level of a link.
function Items.Level(link)
    if not link or type(C_Item) ~= "table" then return nil end
    local level = S.Number(S.CallClean(C_Item.GetDetailedItemLevelInfo, link))
    if level and level > 0 then return level end
    return nil
end

-- Quality color { r, g, b } of a link.
function Items.QualityColor(link)
    if not link or type(C_Item) ~= "table" then return nil end
    local quality = S.Number(S.CallClean(C_Item.GetItemQualityByID, link))
    if not quality then return nil end
    local r, g, b = S.CallClean(C_Item.GetItemQualityColor, quality)
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then
        return { r, g, b }
    end
    local colors = S.Table(ITEM_QUALITY_COLORS)
    return colors and ColorSets.FromColorTable(colors[quality]) or nil
end

-- Item name in its quality color, or nil.
function Items.ColoredName(link)
    if not link then return nil end
    local name = link:match("%[(.-)%]")
    if not name or name == "" then return nil end
    local color = Items.QualityColor(link)
    if not color then return name end
    return ColorSets.Escape(color[1], color[2], color[3]) .. name .. "|r"
end

---------------------------------------------------------------------------
-- Equipped items
---------------------------------------------------------------------------

-- Link of the item in an equipment slot, or nil when empty or unknown.
function Items.EquippedLink(slot)
    local link = S.String(S.CallClean(GetInventoryItemLink, "player", slot))
    if link and link ~= "" then return link end
    return nil
end

-- GUID of the item in an equipment slot, or nil.
function Items.EquippedGUID(slot)
    if type(ItemLocation) ~= "table" or type(C_Item) ~= "table" then return nil end
    local location = S.CallClean(ItemLocation.CreateFromEquipmentSlot, ItemLocation, slot)
    if not location then return nil end
    if S.CallClean(C_Item.DoesItemExist, location) ~= true then return nil end
    return S.String(S.CallClean(C_Item.GetItemGUID, location))
end

-- Equip location of the item in a slot, or nil.
function Items.EquippedEquipLoc(slot)
    local _, equipLoc = Items.Instant(Items.EquippedLink(slot))
    return equipLoc
end
