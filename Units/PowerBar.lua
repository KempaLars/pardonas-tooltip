-- Pardona's ToolTips - resource bar (mana, rage, energy ...) below the tooltip health bar.
--
-- Our own StatusBar, a child of GameTooltip (so it hides with the tooltip), anchored
-- directly below GameTooltipStatusBar with the same width and height. Like Blizzard's
-- health bar it hangs outside the tooltip frame, so it never covers tooltip lines; no
-- Blizzard frame is moved or resized and no field is written to one.
--
-- Values: SetMinMaxValues(0, max) needs a readable maximum; SetValue takes the current
-- value even when it is secret (StatusBar widgets accept secret values). Without a
-- readable maximum above 0 the bar is hidden.
-- Text on the bar: same grades as the health text (Units.ValueText).
-- Color: Blizzard's PowerBarColor[token] (read through _G, may be missing), else blue.
--
-- The bar is an experimental feature: without it (ns.IsExperimental) no bar is shown.
--
-- Updates: UNIT_POWER_UPDATE / UNIT_MAXPOWER for the shown unit mark the bar dirty and
-- refresh it after a short delay; tokens without own events (for example "mouseover")
-- are refreshed periodically. Updates only run while the bar is shown, and only while
-- the tooltip still shows the same unit.

local _, ns = ...
local Units = ns.Units
local S = ns.Secret

local PowerBar = {}
ns.PowerBar = PowerBar

local UPDATE_INTERVAL = 0.25    -- seconds between periodic refreshes
local EVENT_DELAY     = 0.1     -- minimum seconds between event driven refreshes
local GAP             = 2       -- pixels between health bar and resource bar
local DEFAULT_HEIGHT  = 8       -- Blizzard's health bar height, used if it is unreadable
local DEFAULT_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local FALLBACK_COLOR  = { 0, 0, 1 }

local bar, text      -- our StatusBar and its FontString (created on first use)
local currentUnit    -- unit token the bar belongs to
local currentGUID    -- GUID of that unit when readable (nil otherwise)
local dirty = false  -- an event asked for a refresh
local elapsedSinceUpdate = 0

local function HealthBar()
    local health = GameTooltipStatusBar
    if S.FrameUsable(health) then return health end
    return nil
end

local function Hide()
    if bar then bar:Hide() end
end

-- Texture of Blizzard's health bar (file path or file id), else the default bar texture.
local function BarTexture(health)
    local texture = S.Method(health, "GetStatusBarTexture")
    local file = texture and S.Method(texture, "GetTexture")
    if type(file) == "string" or type(file) == "number" then return file end
    return DEFAULT_TEXTURE
end

local function ApplyHeight()
    local health = HealthBar()
    local height = health and S.Number(S.Method(health, "GetHeight"))
    if not height or height <= 0 then height = DEFAULT_HEIGHT end
    bar:SetHeight(height)
end

local function OnUpdate(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    local wait = dirty and EVENT_DELAY or UPDATE_INTERVAL
    if elapsedSinceUpdate < wait then return end
    elapsedSinceUpdate = 0
    PowerBar.Update()
end

local function EnsureBar()
    if bar then return bar end
    local health = HealthBar()
    if not health or not S.FrameUsable(GameTooltip) then return nil end
    local ok, frame = pcall(CreateFrame, "StatusBar", nil, GameTooltip)
    if not ok or not frame then return nil end
    frame:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -GAP)
    frame:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -GAP)
    frame:SetStatusBarTexture(BarTexture(health))
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)
    local fontString = frame:CreateFontString(nil, "OVERLAY")
    fontString:SetFontObject(GameTooltipTextSmall)
    fontString:SetPoint("CENTER", frame, "CENTER", 0, 0)
    fontString:SetTextColor(1, 1, 1)
    frame:Hide()
    frame:SetScript("OnUpdate", OnUpdate)
    bar, text = frame, fontString
    ApplyHeight()
    return bar
end

-- r, g, b from Blizzard's PowerBarColor for the token (or the power type number).
local function PowerColor(token, powerType)
    local colors = S.Table(_G.PowerBarColor)
    if colors then
        local entry = (token and S.Table(colors[token])) or S.Table(colors[powerType])
        if entry then
            local r, g, b = S.Number(S.Field(entry, "r")), S.Number(S.Field(entry, "g")),
                S.Number(S.Field(entry, "b"))
            if r and g and b then return r, g, b end
        end
    end
    return FALLBACK_COLOR[1], FALLBACK_COLOR[2], FALLBACK_COLOR[3]
end

-- True when v can be passed to SetValue (a number, clean or secret). type() is only
-- used on clean values.
local function IsBarValue(v)
    return S.IsSecret(v) or type(v) == "number"
end

-- Refreshes the bar from the current unit.
function PowerBar.Update()
    dirty = false
    local db = ns.db
    if not db or not db.unitMana or not currentUnit or not ns.IsExperimental() then
        Hide()
        return
    end
    -- The token may now point to another unit (for example "mouseover").
    if currentGUID then
        local guid = Units.GUID(currentUnit)
        if guid and guid ~= currentGUID then
            Hide()
            return
        end
    end
    local powerType, token, current, max = Units.PowerValues(currentUnit)
    if not powerType or not max or max <= 0 or not IsBarValue(current) then
        Hide()
        return
    end
    local frame = EnsureBar()
    if not frame then return end
    if not pcall(frame.SetMinMaxValues, frame, 0, max)
        or not pcall(frame.SetValue, frame, current) then
        Hide()
        return
    end
    frame:SetStatusBarColor(PowerColor(token, powerType))

    local value, hasText = Units.PowerText(currentUnit, powerType, current, max)
    if hasText and pcall(text.SetText, text, value) then
        text:Show()
    else
        text:Hide()
    end
    frame:Show()
end

-- Binds the bar to a unit token (nil clears it).
function PowerBar.SetUnit(unit)
    currentUnit = unit
    currentGUID = unit and Units.GUID(unit) or nil
    dirty = false
    elapsedSinceUpdate = 0
    if bar then ApplyHeight() end
    PowerBar.Update()
end

local function Reset()
    currentUnit, currentGUID, dirty = nil, nil, false
    Hide()
end

-- UNIT_POWER_UPDATE / UNIT_MAXPOWER: mark dirty when the event is about the shown unit.
local function OnPowerEvent(_, unit)
    if not bar or not currentUnit or bar:IsShown() ~= true then return end
    local eventUnit = S.String(unit)
    if not eventUnit then return end
    if eventUnit == currentUnit or Units.IsSameUnit(eventUnit, currentUnit) == true then
        dirty = true
    end
end

ns.OnLoad(function()
    if S.FrameUsable(GameTooltip) then
        pcall(GameTooltip.HookScript, GameTooltip, "OnHide", Reset)
        -- The tooltip is reused for items etc. without hiding: drop the bar when its
        -- content is cleared. A new unit tooltip binds it again right after.
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", Reset)
    end
end)

ns.On("UNIT_POWER_UPDATE", OnPowerEvent)
ns.On("UNIT_MAXPOWER", OnPowerEvent)
