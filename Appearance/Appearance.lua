-- Pardona's ToolTips - tooltip appearance: position, scale, colors and border coloring.
--
-- Affects GameTooltip and the comparison tooltips (ShoppingTooltip1/2).
-- Tooltips are only changed through hooksecurefunc, HookScript and
-- TooltipDataProcessor post calls. No Blizzard function is replaced and no field is
-- written to Blizzard frames; per-tooltip state lives in local weak tables.

local _, ns = ...
local S = ns.Secret
local ColorSets = ns.ColorSets

local Appearance = {}
ns.Appearance = Appearance

-- Position keys in display order.
Appearance.POSITIONS = { "cursor", "topleft", "topright", "bottomleft", "bottomright", "center", "blizzard" }

-- Corner positions: anchor point and the direction of the edge distance.
local CORNERS = {
    topleft     = { point = "TOPLEFT",     x = 1,  y = -1 },
    topright    = { point = "TOPRIGHT",    x = -1, y = -1 },
    bottomleft  = { point = "BOTTOMLEFT",  x = 1,  y = 1 },
    bottomright = { point = "BOTTOMRIGHT", x = -1, y = 1 },
}

-- Small distance between mouse cursor and tooltip for the "cursor" position.
local CURSOR_OFFSET_X, CURSOR_OFFSET_Y = 16, 4


local managed = {}                                -- tooltip -> true
local borderColor = setmetatable({}, { __mode = "k" }) -- tooltip -> { r, g, b } from content
local bgChanged = setmetatable({}, { __mode = "k" })   -- tooltip -> true when we tinted the background
local borderChanged = setmetatable({}, { __mode = "k" }) -- tooltip -> true when we tinted the border

function Appearance.IsCorner(position)
    return CORNERS[position] ~= nil
end

local function IsManaged(tooltip)
    if tooltip == nil or S.IsSecret(tooltip) then return false end
    return managed[tooltip] == true
end

local function NineSliceOf(tooltip)
    if not S.FrameUsable(tooltip) then return nil end
    local ok, nine = pcall(function() return tooltip.NineSlice end)
    if not ok or not S.FrameUsable(nine) then return nil end
    return nine
end

---------------------------------------------------------------------------
-- Blizzard default colors (used to undo our tint)
---------------------------------------------------------------------------
local function ColorFromGlobal(value, fallback)
    local color = S.Table(value)
    if color then
        local r, g, b, a = S.Method(color, "GetRGBA")
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return r, g, b, type(a) == "number" and a or 1
        end
    end
    return fallback[1], fallback[2], fallback[3], fallback[4]
end

local function BlizzardBackground()
    return ColorFromGlobal(TOOLTIP_DEFAULT_BACKGROUND_COLOR, ColorSets.BLIZZARD_BACKGROUND)
end

local function BlizzardBorder()
    return ColorFromGlobal(TOOLTIP_DEFAULT_COLOR, ColorSets.BLIZZARD_BORDER)
end

---------------------------------------------------------------------------
-- Border color from tooltip content (secret-safe; nil when unknown)
---------------------------------------------------------------------------
local function ColorOf(c)
    c = S.Table(c)
    if not c then return nil end
    local r, g, b = S.Number(S.Field(c, "r")), S.Number(S.Field(c, "g")), S.Number(S.Field(c, "b"))
    if r and g and b then return { r, g, b } end
    return nil
end

local function ItemBorderColor(tooltip, data)
    if type(C_Item) ~= "table" then return nil end

    local quality
    local _, link = S.Method(tooltip, "GetItem")
    link = S.String(link)
    if link then
        quality = S.Number(S.CallClean(C_Item.GetItemQualityByID, link))
    end
    if not quality then
        local id = S.Number(S.Field(data, "id"))
        if id then quality = S.Number(S.CallClean(C_Item.GetItemQualityByID, id)) end
    end
    if not quality then return nil end

    local r, g, b = S.CallClean(C_Item.GetItemQualityColor, quality)
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then
        return { r, g, b }
    end
    local colors = S.Table(ITEM_QUALITY_COLORS)
    return colors and ColorOf(colors[quality]) or nil
end

local function UnitBorderColor(tooltip)
    local _, unit = S.Method(tooltip, "GetUnit")
    unit = S.String(unit)
    if not unit then return nil end

    local isPlayer = S.Boolean(S.CallClean(UnitIsPlayer, unit))
    if isPlayer == nil then return nil end

    if isPlayer then
        local _, classFile = S.CallClean(UnitClass, unit)
        classFile = S.String(classFile)
        if not classFile then return nil end
        local classColor
        if type(C_ClassColor) == "table" then
            classColor = ColorOf(S.CallClean(C_ClassColor.GetClassColor, classFile))
        end
        if not classColor then
            local colors = S.Table(RAID_CLASS_COLORS)
            classColor = colors and ColorOf(colors[classFile]) or nil
        end
        return classColor
    end

    local reaction = S.Number(S.CallClean(UnitReaction, unit, "player"))
    if not reaction then return nil end
    if reaction <= 3 then
        return ColorSets.REACTION.hostile
    elseif reaction == 4 then
        return ColorSets.REACTION.neutral
    end
    return ColorSets.REACTION.friendly
end

local function ContentBorderColor(tooltip, data)
    local db = ns.db
    if not db or not db.colorBorder then return nil end
    local types = S.Table(Enum) and S.Table(Enum.TooltipDataType)
    local dataType = S.Number(S.Field(data, "type"))
    if not types or not dataType then return nil end
    if dataType == types.Item then
        return ItemBorderColor(tooltip, data)
    elseif dataType == types.Unit then
        return UnitBorderColor(tooltip)
    end
    return nil
end

---------------------------------------------------------------------------
-- Applying settings to a tooltip
---------------------------------------------------------------------------
local function ApplyScale(tooltip)
    local db = ns.db
    if not db or not S.FrameUsable(tooltip) then return end
    local scale = db.scale / 100
    if S.Method(tooltip, "GetScale") ~= scale then
        S.Method(tooltip, "SetScale", scale)
    end
end

local function ApplyStyle(tooltip)
    local db = ns.db
    local nine = NineSliceOf(tooltip)
    if not db or not nine then return end
    local set = ColorSets.Current()

    -- Background
    if set.background then
        local c = set.background
        S.Method(nine, "SetCenterColor", c[1], c[2], c[3], set.bgAlpha or 1)
        bgChanged[tooltip] = true
    elseif bgChanged[tooltip] then
        S.Method(nine, "SetCenterColor", BlizzardBackground())
        bgChanged[tooltip] = nil
    end

    -- Border: content color (if enabled) wins over the set color.
    local c = (db.colorBorder and borderColor[tooltip]) or set.border
    if c then
        S.Method(nine, "SetBorderColor", c[1], c[2], c[3], c[4] or 1)
        borderChanged[tooltip] = true
    elseif borderChanged[tooltip] then
        S.Method(nine, "SetBorderColor", BlizzardBorder())
        borderChanged[tooltip] = nil
    end
end

---------------------------------------------------------------------------
-- Hooks
---------------------------------------------------------------------------

-- Runs after Blizzard anchored a tooltip with the default anchor.
local function OnSetDefaultAnchor(tooltip, parent)
    local db = ns.db
    if not db or db.position == "blizzard" then return end
    if S.IsSecret(tooltip) or tooltip ~= GameTooltip or not S.FrameUsable(tooltip) then return end

    local position = db.position
    if position == "cursor" then
        local owner = parent
        if owner == nil or S.IsSecret(owner) then owner = UIParent end
        S.Method(tooltip, "SetOwner", owner, "ANCHOR_CURSOR_RIGHT", CURSOR_OFFSET_X, CURSOR_OFFSET_Y)
        return
    end

    S.Method(tooltip, "ClearAllPoints")
    local corner = CORNERS[position]
    if corner then
        -- Offsets are in the tooltip's own (scaled) coordinates.
        local distance = db.offset / (db.scale / 100)
        S.Method(tooltip, "SetPoint", corner.point, UIParent, corner.point,
            corner.x * distance, corner.y * distance)
    else
        S.Method(tooltip, "SetPoint", "CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function OnTooltipData(tooltip, data)
    if not IsManaged(tooltip) then return end
    borderColor[tooltip] = ContentBorderColor(tooltip, data)
    ApplyStyle(tooltip)
end

local function OnTooltipShow(tooltip)
    ApplyScale(tooltip)
    ApplyStyle(tooltip)
end

local function OnTooltipHide(tooltip)
    borderColor[tooltip] = nil
end

-- Blizzard re-applies its backdrop style at times; put our colors back afterwards.
local function OnBackdropStyle(tooltip)
    if IsManaged(tooltip) then ApplyStyle(tooltip) end
end

local function InstallHooks()
    local tooltips = { GameTooltip, ShoppingTooltip1, ShoppingTooltip2 }
    for i = 1, 3 do
        local tooltip = tooltips[i]
        if S.FrameUsable(tooltip) and not managed[tooltip] then
            managed[tooltip] = true
            pcall(tooltip.HookScript, tooltip, "OnShow", OnTooltipShow)
            pcall(tooltip.HookScript, tooltip, "OnHide", OnTooltipHide)
        end
    end

    if type(GameTooltip_SetDefaultAnchor) == "function" then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", OnSetDefaultAnchor)
    end
    if type(SharedTooltip_SetBackdropStyle) == "function" then
        hooksecurefunc("SharedTooltip_SetBackdropStyle", OnBackdropStyle)
    end

    local processor = TooltipDataProcessor
    if type(processor) == "table" and type(processor.AddTooltipPostCall) == "function" then
        if processor.AllTypes ~= nil then
            processor.AddTooltipPostCall(processor.AllTypes, OnTooltipData)
        else
            local types = S.Table(Enum) and S.Table(Enum.TooltipDataType)
            if types then
                if types.Item then processor.AddTooltipPostCall(types.Item, OnTooltipData) end
                if types.Unit then processor.AddTooltipPostCall(types.Unit, OnTooltipData) end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Applies all appearance settings immediately (called after every option change).
function Appearance.Refresh()
    if not ns.db then return end
    ns.Fonts.Apply()
    for tooltip in pairs(managed) do
        ApplyScale(tooltip)
        ApplyStyle(tooltip)
    end
end

ns.OnLoad(InstallHooks)
ns.OnLogin(Appearance.Refresh)
