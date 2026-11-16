-- Pardona's ToolTips - item tooltip content.
--
--   * Item level of equipment, right-aligned in the title line ("iLvl 25"). If that
--     column is used or not accessible, an own line at the start of our block.
--     GameTooltip, ItemRefTooltip and the comparison tooltips ShoppingTooltip1/2.
--   * Always visible gear comparison (see Compare.lua) in GameTooltip and ItemRefTooltip.
--   * Hides the "You haven't collected this appearance" line before it is drawn.
--
-- Blizzard lines and lines of other addons are not changed.

local _, ns = ...
local L = ns.L
local S = ns.Secret
local Units = ns.Units
local Items = ns.Items
local Format = ns.Format
local ColorSets = ns.ColorSets

local ItemInfo = {}
ns.ItemInfo = ItemInfo

local TITLE_SEARCH_LINES = 3      -- the item name is in one of the first lines

local levelTooltips = {}          -- tooltip -> true: item level shown
local compareTooltips = {}        -- tooltip -> true: comparison shown
local showsItem = setmetatable({}, { __mode = "k" }) -- tooltip -> true while it shows an item

---------------------------------------------------------------------------
-- Item level
---------------------------------------------------------------------------

-- Index of the title line (the line containing the item name), or nil.
local function TitleLine(tooltip, link)
    local name = link:match("%[(.-)%]")
    if not name or name == "" then return nil end
    local count = math.min(TITLE_SEARCH_LINES, Units.NumLines(tooltip))
    for i = 1, count do
        local text = Units.LineText(Units.Line(tooltip, "Left", i))
        if text and text:find(name, 1, true) then return i end
    end
    return nil
end

-- Puts "iLvl N" into the free right column of the title line. False when not possible.
local function PlaceInTitle(tooltip, link, level)
    local index = TitleLine(tooltip, link)
    if not index then return false end
    local right = Units.Line(tooltip, "Right", index)
    if not right then return false end
    -- The column must be empty; a secret text counts as used.
    local text = S.Call(right.GetText, right)
    if S.IsSecret(text) or (text ~= nil and text ~= "") then return false end
    local r, g, b = ColorSets.TextColor("hint")
    S.Method(right, "SetText", L.ITEM_LEVEL_SHORT:format(Format.Number(level)))
    S.Method(right, "SetTextColor", r, g, b)
    S.Method(right, "Show")
    return true
end

---------------------------------------------------------------------------
-- Comparison mode
---------------------------------------------------------------------------
local function CompareWanted()
    local mode = ns.db.itemCompare
    if mode == "always" then return true end
    if mode == "shift" then return S.CallClean(IsShiftKeyDown) == true end
    return false
end

---------------------------------------------------------------------------
-- Tooltip handling
---------------------------------------------------------------------------
local function OnItemTooltip(tooltip, data)
    if S.IsSecret(tooltip) then return end
    local wantsLevel, wantsCompare = levelTooltips[tooltip], compareTooltips[tooltip]
    if not wantsLevel and not wantsCompare then return end
    local db = ns.db
    if not db then return end

    showsItem[tooltip] = true
    local link = Items.LinkFromTooltip(tooltip, data)
    if not link or not Items.IsEquipment(link) then return end

    if wantsLevel and db.itemLevel then
        local level = Items.Level(link)
        if level and not PlaceInTitle(tooltip, link, level) then
            Units.AddPair(tooltip, L.LINE_ITEM_LEVEL, Format.Number(level))
        end
    end

    if wantsCompare and CompareWanted() then
        ns.Compare.Add(tooltip, link, data)
    end
end

-- Line pre-call: returning true drops the line before it is drawn (no empty line).
local function OnLine(_, lineData)
    local db = ns.db
    if not db or not db.itemHideAppearance then return false end
    local unknown = S.String(TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN)
    if not unknown then return false end
    return S.String(S.Field(lineData, "leftText")) == unknown
end

-- "Only with Shift": rebuild shown item tooltips when Shift is pressed or released.
local function OnModifierChanged(_, key)
    local db = ns.db
    if not db or db.itemCompare ~= "shift" then return end
    key = S.String(key)
    if key ~= "LSHIFT" and key ~= "RSHIFT" then return end
    for tooltip in pairs(compareTooltips) do
        if showsItem[tooltip] and S.Method(tooltip, "IsShown") == true then
            S.Method(tooltip, "RefreshData")
        end
    end
end

local function OnTooltipHide(tooltip)
    showsItem[tooltip] = nil
end

local function Protected(fn)
    return function(...)
        local ok, result = pcall(fn, ...)
        if ok then return result end
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(result) end
        return nil
    end
end

ns.OnLoad(function()
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        if S.FrameUsable(tooltip) then
            levelTooltips[tooltip] = true
            compareTooltips[tooltip] = true
            pcall(tooltip.HookScript, tooltip, "OnHide", OnTooltipHide)
        end
    end
    for _, tooltip in ipairs({ ShoppingTooltip1, ShoppingTooltip2 }) do
        if S.FrameUsable(tooltip) then levelTooltips[tooltip] = true end
    end

    local processor = TooltipDataProcessor
    local types = S.Table(Enum) and S.Table(Enum.TooltipDataType)
    if type(processor) ~= "table" then return end
    if type(processor.AddTooltipPostCall) == "function" and types and types.Item then
        processor.AddTooltipPostCall(types.Item, Protected(OnItemTooltip))
    end
    if type(processor.AddLinePreCall) == "function" and processor.AllTypes ~= nil then
        processor.AddLinePreCall(processor.AllTypes, Protected(OnLine))
    end
end)

ns.On("MODIFIER_STATE_CHANGED", OnModifierChanged)
