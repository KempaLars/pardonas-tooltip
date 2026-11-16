-- Pardona's ToolTips - disenchant chances, disenchant value and sell recommendation.
--
-- Shown for disenchantable items only: uncommon, rare or epic weapons and armor (no shirt
-- or tabard). Items that are not soulbound always get the block (they can be sent to an
-- alt); soulbound items only when the character has learned Enchanting. Chat links and
-- vendor items count as not bound unless they bind on pickup.
--
-- Lines (each can be switched off):
--   Disenchant:        chances from Data/Disenchant.lua (+ missing skill note)
--   Disenchant value:  TSM price source "Destroy"                         (TSM only)
--   Recommendation:    vendor, auction house or disenchant, highest wins   (TSM only)

local _, ns = ...
local L = ns.L
local S = ns.Secret
local Items = ns.Items
local Units = ns.Units
local Format = ns.Format
local Prices = ns.Prices
local ColorSets = ns.ColorSets
local Professions = ns.Professions

local Disenchant = {}
ns.Disenchant = Disenchant

local DATA = ns.DisenchantData
local QUALITY_KEYS = { [2] = "uncommon", [3] = "rare", [4] = "epic" }
local SEPARATOR = " · "
local WRAP_LENGTH = 42      -- characters of plain text per line before wrapping
local INDENT = "  "
local SALE_RATE_SCALE = 1000    -- DBRegionSaleRate is a fraction (0.737)
local SOLD_PER_DAY_SCALE = 100  -- DBRegionSoldPerDay has decimals (0.42)

---------------------------------------------------------------------------
-- Data lookup
---------------------------------------------------------------------------
local function FindRow(rows, level)
    if not rows then return nil end
    for i = 1, #rows do
        local row = rows[i]
        if level >= row.min and level <= row.max then return row end
    end
    return nil
end

local function SkillFrom(list, level)
    if not list then return nil end
    for i = 1, #list do
        local entry = list[i]
        if level >= entry[1] and level <= entry[2] then return entry[3] end
    end
    return nil
end

-- Results and required skill for quality (2-4), item level and weapon/armor.
function Disenchant.Lookup(quality, level, isWeapon)
    local key = QUALITY_KEYS[quality]
    if not key then return nil end
    level = math.floor(level + 0.5)
    local rows
    if key == "uncommon" then
        rows = DATA.uncommon[isWeapon and "weapon" or "armor"]
    else
        rows = DATA[key]
    end
    local row = FindRow(rows, level)
    local skill = SkillFrom(DATA.skill[key], level)
    if not skill and key == "epic" then skill = SkillFrom(DATA.skill.rare, level) end
    return row and row.results or nil, skill
end

---------------------------------------------------------------------------
-- Item facts
---------------------------------------------------------------------------

-- quality, sell price, class ID and bind type of a link (each may be nil).
local function ItemFacts(link)
    if type(C_Item) ~= "table" then return nil end
    local _, _, quality, _, _, _, _, _, _, _, sellPrice, classID, _, bindType =
        S.CallClean(C_Item.GetItemInfo, link)
    return S.Number(quality), S.Number(sellPrice), S.Number(classID), S.Number(bindType)
end

local function BindOnPickup()
    local binds = S.Table(Enum) and S.Table(Enum.ItemBind)
    return (binds and S.Number(S.Field(binds, "OnAcquire"))) or 1
end

-- True when the concrete item is soulbound. Without an item GUID (chat link, vendor)
-- only "binds when picked up" counts as bound.
local function IsBound(data, bindType)
    local guid = S.String(S.Field(data, "guid"))
    if guid and guid ~= "" and type(C_Item) == "table" then
        local location = S.CallClean(C_Item.GetItemLocation, guid)
        if location then
            local bound = S.Boolean(S.CallClean(C_Item.IsBound, location))
            if bound ~= nil then return bound end
        end
    end
    return bindType == BindOnPickup()
end

---------------------------------------------------------------------------
-- Disenchant line
---------------------------------------------------------------------------
local function MaterialName(itemID)
    local name = type(C_Item) == "table" and S.String(S.CallClean(C_Item.GetItemNameByID, itemID)) or nil
    if name and name ~= "" then return name end
    -- Not cached yet: request it; the next tooltip build shows the name.
    if type(C_Item) == "table" then S.CallClean(C_Item.RequestLoadItemDataByID, itemID) end
    return L.ITEM_LOADING
end

local function ResultText(result)
    local itemID, chance, minCount, maxCount = result[1], result[2], result[3], result[4]
    local text = Format.Chance(chance) .. " " .. MaterialName(itemID)
    if maxCount > 1 then
        local count = minCount == maxCount and tostring(minCount) or (minCount .. "–" .. maxCount)
        text = text .. " (" .. count .. ")"
    end
    return text
end

-- Splits the result texts into lines of about WRAP_LENGTH characters.
local function WrapSegments(segments, firstLineUsed)
    local lines, current, length = {}, nil, firstLineUsed
    for i = 1, #segments do
        local segment = segments[i]
        if current and length + #SEPARATOR + #segment > WRAP_LENGTH then
            lines[#lines + 1] = current
            current, length = nil, #INDENT
        end
        if current then
            current = current .. SEPARATOR .. segment
            length = length + #SEPARATOR + #segment
        else
            current = segment
            length = length + #segment
        end
    end
    if current then lines[#lines + 1] = current end
    return lines
end

local function AddChances(tooltip, results, skillNote)
    local segments = {}
    for i = 1, #results do segments[#segments + 1] = ResultText(results[i]) end
    local label = L.LINE_DISENCHANT
    local lines = WrapSegments(segments, #label + 1)
    if #lines == 0 then return end

    local labelColor = ColorSets.TextEscape("label")
    local valueColor = ColorSets.TextEscape("value")
    if skillNote then
        lines[#lines] = lines[#lines] .. "|r " .. ColorSets.TextEscape("negative") .. skillNote
    end
    for i = 1, #lines do
        local text
        if i == 1 then
            text = labelColor .. label .. "|r " .. valueColor .. lines[i] .. "|r"
        else
            text = INDENT .. valueColor .. lines[i] .. "|r"
        end
        S.Method(tooltip, "AddLine", text, 1, 1, 1)
    end
end

---------------------------------------------------------------------------
-- Recommendation
---------------------------------------------------------------------------

-- Returns choiceLabel, value, slowSeller, destroyValue (any may be nil).
local function Recommend(link, sellPrice, disenchantAllowed)
    local db = ns.db
    local itemString = Prices.ItemString(link)
    if not itemString then return nil end
    local afterFee = (100 - db.ahFee) / 100

    local vendor = Prices.Value("VendorSell", itemString)
    if not vendor and sellPrice and sellPrice > 0 then vendor = sellPrice end

    local market = Prices.Value("DBMarket", itemString) or Prices.Value("DBMinBuyout", itemString)
    -- Key figures are requested scaled, because TSM rounds results to whole numbers.
    local saleRate = Prices.Metric("DBRegionSaleRate", SALE_RATE_SCALE, itemString)
    local soldPerDay = Prices.Metric("DBRegionSoldPerDay", SOLD_PER_DAY_SCALE, itemString)
    local slow = (saleRate ~= nil and saleRate < db.minSaleRate)
        or (soldPerDay ~= nil and soldPerDay < db.minSoldPerDay)
    local auction = (market and market > 0 and not slow) and market * afterFee or nil

    local destroy = Prices.Value("Destroy", itemString)
    local disenchant = (destroy and destroy > 0 and disenchantAllowed) and destroy * afterFee or nil

    local choice, best
    if vendor and vendor > 0 then choice, best = L.RECOMMEND_VENDOR, vendor end
    if auction and (not best or auction > best) then choice, best = L.RECOMMEND_AUCTION, auction end
    if disenchant and (not best or disenchant > best) then choice, best = L.RECOMMEND_DISENCHANT, disenchant end
    return choice, best, slow and market ~= nil, destroy
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Adds the disenchant/price block for the item shown in tooltip.
function Disenchant.Add(tooltip, link, data)
    local db = ns.db
    if not db or not (db.deChances or db.deValue or db.deRecommend) then return end

    local quality, sellPrice, classID, bindType = ItemFacts(link)
    if not quality or not QUALITY_KEYS[quality] or not classID then return end
    local itemClass = S.Table(Enum) and S.Table(Enum.ItemClass)
    if not itemClass then return end
    local isWeapon = classID == S.Number(S.Field(itemClass, "Weapon"))
    local isArmor = classID == S.Number(S.Field(itemClass, "Armor"))
    if not isWeapon and not isArmor then return end

    local bound = IsBound(data, bindType)
    local knows = Professions.KnowsEnchanting()
    if bound and not knows then return end

    local level = Items.Level(link)
    local results, requiredSkill
    if level then results, requiredSkill = Disenchant.Lookup(quality, level, isWeapon) end

    local rank = Professions.EnchantingRank()
    local skillTooLow = knows and requiredSkill ~= nil and rank ~= nil and rank < requiredSkill

    if db.deChances and results then
        local note = skillTooLow and L.SKILL_NEEDED:format(requiredSkill) or nil
        AddChances(tooltip, results, note)
    end

    if not Prices.Available() then return end
    local disenchantAllowed = (knows and not skillTooLow) or not bound
    local choice, value, slow, destroy = Recommend(link, sellPrice, disenchantAllowed)

    if db.deValue and destroy and destroy > 0 then
        Units.AddPair(tooltip, L.LINE_DISENCHANT_VALUE, Prices.Money(destroy))
    end
    if db.deRecommend and choice then
        local text = L.RECOMMEND_FORMAT:format(choice, Prices.Money(value))
        if slow then
            text = text .. " " .. ColorSets.TextEscape("hint") .. L.SLOW_SELLER .. "|r"
        end
        Units.AddPair(tooltip, L.LINE_RECOMMENDATION, text)
    end
end
