-- Pardona's ToolTips - always visible gear comparison.
--
-- Adds one block per compared equipment slot below the Blizzard lines of GameTooltip and
-- ItemRefTooltip. The numbers come from the same API Blizzard's own "If you replace this
-- item" section uses: C_TooltipComparison.GetItemComparisonDelta (see
-- Blizzard_SharedXMLGame/Tooltip/TooltipComparisonManager.lua). If that API is missing
-- or fails, the difference of C_Item.GetItemStats is used instead.
--
-- Slots:
--   rings, trinkets   one block per equipped item (Ring 1, Ring 2 / Trinket 1, Trinket 2)
--   one-hand weapon   against the main hand; with dual wield also against the off-hand
--   two-hand weapon   one block against main and off-hand together
--   shield, off-hand  against the off-hand, or against an equipped two-hand weapon
--   empty slot        "(empty slot)" with all values of the new item as gains

local _, ns = ...
local L = ns.L
local S = ns.Secret
local Items = ns.Items
local Units = ns.Units
local Format = ns.Format
local ColorSets = ns.ColorSets

local Compare = {}
ns.Compare = Compare

local SLOT = Items.SLOT
local INDENT = "  "

-- Equip location -> single slot for the simple cases.
local SINGLE_SLOT = {
    INVTYPE_HEAD = SLOT.HEAD, INVTYPE_NECK = SLOT.NECK, INVTYPE_SHOULDER = SLOT.SHOULDER,
    INVTYPE_CHEST = SLOT.CHEST, INVTYPE_ROBE = SLOT.CHEST, INVTYPE_WAIST = SLOT.WAIST,
    INVTYPE_LEGS = SLOT.LEGS, INVTYPE_FEET = SLOT.FEET, INVTYPE_WRIST = SLOT.WRIST,
    INVTYPE_HAND = SLOT.HANDS, INVTYPE_CLOAK = SLOT.BACK,
    INVTYPE_WEAPONMAINHAND = SLOT.MAIN_HAND, INVTYPE_WEAPONOFFHAND = SLOT.OFF_HAND,
    INVTYPE_RANGED = SLOT.RANGED, INVTYPE_RANGEDRIGHT = SLOT.RANGED,
    INVTYPE_THROWN = SLOT.RANGED, INVTYPE_RELIC = SLOT.RANGED,
}

-- Fallback stat order (keys of C_Item.GetItemStats); others follow alphabetically.
local STAT_ORDER = {
    "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    "RESISTANCE0_NAME",
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_SPIRIT_SHORT",
}
local DECIMAL_STATS = { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = true }

---------------------------------------------------------------------------
-- Which slots to compare
---------------------------------------------------------------------------

-- List of targets { slot, paired, hint } for an equip location, or nil.
local function Targets(equipLoc)
    if equipLoc == "INVTYPE_FINGER" then
        return {
            { slot = SLOT.FINGER1, hint = L.SLOT_RING:format(1) },
            { slot = SLOT.FINGER2, hint = L.SLOT_RING:format(2) },
        }
    elseif equipLoc == "INVTYPE_TRINKET" then
        return {
            { slot = SLOT.TRINKET1, hint = L.SLOT_TRINKET:format(1) },
            { slot = SLOT.TRINKET2, hint = L.SLOT_TRINKET:format(2) },
        }
    elseif equipLoc == "INVTYPE_2HWEAPON" then
        return { { slot = SLOT.MAIN_HAND, paired = SLOT.OFF_HAND } }
    elseif equipLoc == "INVTYPE_WEAPON" then
        local mainHandIsTwoHand = Items.EquippedEquipLoc(SLOT.MAIN_HAND) == "INVTYPE_2HWEAPON"
        if S.CallClean(CanDualWield) == true and not mainHandIsTwoHand then
            return {
                { slot = SLOT.MAIN_HAND, hint = S.String(INVTYPE_WEAPONMAINHAND) },
                { slot = SLOT.OFF_HAND, hint = S.String(INVTYPE_WEAPONOFFHAND) },
            }
        end
        return { { slot = SLOT.MAIN_HAND } }
    elseif equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then
        if Items.EquippedEquipLoc(SLOT.MAIN_HAND) == "INVTYPE_2HWEAPON" then
            return { { slot = SLOT.MAIN_HAND } }
        end
        return { { slot = SLOT.OFF_HAND } }
    end
    local slot = SINGLE_SLOT[equipLoc]
    if slot then return { { slot = slot } } end
    return nil
end

---------------------------------------------------------------------------
-- Delta lines: { { text = "+7 Armor", negative = false }, ... }
---------------------------------------------------------------------------
local function StripColors(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|cn[^:]*:", "")
    text = text:gsub("|r", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function FromDeltaStrings(delta)
    local lines = {}
    delta = S.Table(delta)
    if not delta then return lines end
    for i = 1, #delta do
        local text = S.String(delta[i])
        if text then
            text = StripColors(text)
            if text ~= "" then
                lines[#lines + 1] = { text = text, negative = text:sub(1, 1) == "-" }
            end
        end
    end
    return lines
end

-- Delta via Blizzard's comparison API. Returns lines, or nil when it cannot be used.
local function ApiDelta(newItem, equippedGUID, pairedGUID)
    local api = S.Table(C_TooltipComparison)
    local fn = api and api.GetItemComparisonDelta
    if type(fn) ~= "function" or not newItem or not equippedGUID then return nil end
    local ok, delta
    if pairedGUID then
        -- false: the paired (off-hand) item is replaced as well, like Blizzard's
        -- "If you replace these items" for two-hand weapons.
        ok, delta = pcall(fn, newItem, { guid = equippedGUID }, { guid = pairedGUID }, false)
    else
        ok, delta = pcall(fn, newItem, { guid = equippedGUID })
    end
    if not ok or S.IsSecret(delta) then return nil end
    return FromDeltaStrings(delta)
end

local function ReadStats(link, into, factor)
    if not link or type(C_Item) ~= "table" then return false end
    local stats = S.Table(S.CallClean(C_Item.GetItemStats, link))
    if not stats then return false end
    for key, value in pairs(stats) do
        key, value = S.String(key), S.Number(value)
        if key and value then into[key] = (into[key] or 0) + value * factor end
    end
    return true
end

local function StatText(key, value)
    local name = S.String(_G[key])
    if not name or name == "" then return nil end
    local amount = math.abs(value)
    local number = DECIMAL_STATS[key] and Format.Decimal(amount, 1) or Format.Number(amount)
    return (value < 0 and "-" or "+") .. number .. " " .. name
end

-- Delta from item stats (fallback). equippedLinks may be empty (empty slot).
local function StatsDelta(newLink, equippedLinks)
    local diff = {}
    if not ReadStats(newLink, diff, 1) then return nil end
    for i = 1, #equippedLinks do
        if not ReadStats(equippedLinks[i], diff, -1) then return nil end
    end

    local keys, seen = {}, {}
    for i = 1, #STAT_ORDER do
        keys[#keys + 1] = STAT_ORDER[i]
        seen[STAT_ORDER[i]] = true
    end
    local others = {}
    for key in pairs(diff) do
        if not seen[key] then others[#others + 1] = key end
    end
    table.sort(others)
    for i = 1, #others do keys[#keys + 1] = others[i] end

    local lines = {}
    for i = 1, #keys do
        local value = diff[keys[i]]
        if value and math.abs(value) >= 0.05 then
            local text = StatText(keys[i], value)
            if text then lines[#lines + 1] = { text = text, negative = value < 0 } end
        end
    end
    return lines
end

---------------------------------------------------------------------------
-- Blocks
---------------------------------------------------------------------------
local function AddBlock(tooltip, header, lines)
    Units.AddRoleLine(tooltip, header, "label")
    if #lines == 0 then
        Units.AddRoleLine(tooltip, INDENT .. L.COMPARE_NO_CHANGE, "hint")
        return
    end
    for i = 1, #lines do
        Units.AddRoleLine(tooltip, INDENT .. lines[i].text, lines[i].negative and "negative" or "positive")
    end
end

local function Header(names, hint)
    local subject = table.concat(names, " + ")
    if hint and hint ~= "" then
        -- The item names end with |r, so the hint gets the label color explicitly.
        subject = subject .. ColorSets.TextEscape("label") .. " (" .. hint .. ")|r"
    end
    return L.INSTEAD_OF:format(subject)
end

-- Builds one block for target; returns false when nothing could be computed.
local function CompareTarget(tooltip, newItem, newLink, target)
    local slots = { target.slot }
    if target.paired then slots[2] = target.paired end

    local links, guids, names = {}, {}, {}
    local anyMissingGUID = false
    for i = 1, #slots do
        local link = Items.EquippedLink(slots[i])
        if link then
            links[#links + 1] = link
            names[#names + 1] = Items.ColoredName(link) or "?"
            local guid = Items.EquippedGUID(slots[i])
            if guid then guids[#guids + 1] = guid else anyMissingGUID = true end
        end
    end

    local lines
    if #links == 0 then
        lines = StatsDelta(newLink, {})
        if not lines then return false end
        AddBlock(tooltip, Header({ L.EMPTY_SLOT }, target.hint), lines)
        return true
    end

    if not anyMissingGUID then lines = ApiDelta(newItem, guids[1], guids[2]) end
    if not lines then lines = StatsDelta(newLink, links) end
    if not lines then return false end
    AddBlock(tooltip, Header(names, target.hint), lines)
    return true
end

-- True when the shown item is the one equipped in one of the target slots.
local function IsEquipped(newGUID, newLink, targets)
    for i = 1, #targets do
        local slots = { targets[i].slot, targets[i].paired }
        for j = 1, #slots do
            if newGUID and Items.EquippedGUID(slots[j]) == newGUID then return true end
            if not newGUID and Items.EquippedLink(slots[j]) == newLink then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Adds the comparison blocks for the item shown in tooltip.
function Compare.Add(tooltip, link, data)
    local _, equipLoc = Items.Instant(link)
    local targets = equipLoc and Targets(equipLoc)
    if not targets then return end
    -- Only items the character can wear; unknown means no comparison.
    if ns.Wearable.Check(link) ~= true then return end

    local newGUID = S.String(S.Field(data, "guid"))
    if newGUID == "" then newGUID = nil end
    if IsEquipped(newGUID, link, targets) then return end

    local newItem = newGUID and { guid = newGUID } or { hyperlink = link }
    for i = 1, #targets do
        CompareTarget(tooltip, newItem, link, targets[i])
    end
end
