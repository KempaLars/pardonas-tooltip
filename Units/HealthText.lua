-- Pardona's ToolTips - health text on the tooltip health bar.
--
-- The text is our own FontString created on GameTooltipStatusBar; no field is written
-- to the Blizzard frame. What it shows depends on what the game lets addons read
-- (see Units.Health):
--   exact values readable    "1,234 / 2,000 (62%)"
--   only percentage readable "62%"
--   percentage secret        "62%" as a secret string, shown through SetText only
--   nothing readable         text hidden, the bar stays as Blizzard drew it
--
-- The unit's GUID is not required: when it is readable it is used to notice that the
-- token now points to another unit; otherwise the text is reset when the tooltip shows
-- another unit or hides.

local _, ns = ...
local L = ns.L
local Units = ns.Units
local Format = ns.Format
local S = ns.Secret

local HealthText = {}
ns.HealthText = HealthText

local text           -- our FontString (created on first use)
local currentUnit    -- unit token the text belongs to
local currentGUID    -- GUID of that unit when readable (nil otherwise)

local function Hide()
    if text then text:Hide() end
end

local function EnsureText()
    if text then return text end
    local bar = GameTooltipStatusBar
    if not S.FrameUsable(bar) then return nil end
    local ok, fontString = pcall(bar.CreateFontString, bar, nil, "OVERLAY")
    if not ok or not fontString then return nil end
    fontString:SetFontObject(GameTooltipTextSmall)
    fontString:SetPoint("CENTER", bar, "CENTER", 0, 0)
    fontString:SetTextColor(1, 1, 1)
    fontString:Hide()
    text = fontString
    return text
end

-- Text for the current unit: a plain string, a secret string or nil.
local function BuildText(unit)
    local grade, a, b = Units.Health(unit)
    if grade == "exact" then
        return L.HEALTH_FORMAT:format(Format.Ratio(a, b), Format.Percent(a / b * 100))
    elseif grade == "percent" then
        return Format.Percent(a)
    elseif grade == "secret" then
        return Format.SecretPercent(a)
    end
    return nil
end

-- Refreshes the text from the current unit (called on unit change and bar updates).
function HealthText.Update()
    local db = ns.db
    if not db or not db.unitHealthText or not currentUnit then
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
    local value = BuildText(currentUnit)
    if value == nil then
        Hide()
        return
    end
    local fontString = EnsureText()
    if not fontString then return end
    -- SetText accepts secret strings; protected in case a client build does not.
    if not pcall(fontString.SetText, fontString, value) then
        Hide()
        return
    end
    fontString:Show()
end

-- Binds the text to a unit token (nil clears it).
function HealthText.SetUnit(unit)
    currentUnit = unit
    currentGUID = unit and Units.GUID(unit) or nil
    HealthText.Update()
end

local function OnTooltipHide()
    currentUnit, currentGUID = nil, nil
    Hide()
end

ns.OnLoad(function()
    local bar = GameTooltipStatusBar
    if S.FrameUsable(bar) then
        pcall(bar.HookScript, bar, "OnValueChanged", HealthText.Update)
    end
    if S.FrameUsable(GameTooltip) then
        pcall(GameTooltip.HookScript, GameTooltip, "OnHide", OnTooltipHide)
    end
end)
