-- Pardona's ToolTips - health text on the tooltip health bar.
--
-- Shows "current / max (percent)" on GameTooltipStatusBar. The text is our own
-- FontString created on that bar; no field is written to the Blizzard frame. When a
-- value is secret, the text is hidden and the bar stays as Blizzard drew it.

local _, ns = ...
local L = ns.L
local Units = ns.Units
local Format = ns.Format
local S = ns.Secret

local HealthText = {}
ns.HealthText = HealthText

local text           -- our FontString (created on first use)
local currentUnit    -- unit token the text belongs to
local currentGUID    -- GUID of that unit (to notice a different unit behind the same token)

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

-- Refreshes the text from the current unit (called on unit change and bar updates).
function HealthText.Update()
    local db = ns.db
    if not db or not db.unitHealthText or not currentUnit then
        Hide()
        return
    end
    -- The token may now point to another unit (for example "mouseover").
    if Units.GUID(currentUnit) ~= currentGUID then
        Hide()
        return
    end
    local health = S.Number(S.CallClean(UnitHealth, currentUnit))
    local maxHealth = S.Number(S.CallClean(UnitHealthMax, currentUnit))
    if not health or not maxHealth or maxHealth <= 0 then
        Hide()
        return
    end
    local fontString = EnsureText()
    if not fontString then return end
    fontString:SetText(L.HEALTH_FORMAT:format(Format.Ratio(health, maxHealth),
        Format.Percent(health / maxHealth * 100)))
    fontString:Show()
end

-- Binds the text to a unit token (nil clears it).
function HealthText.SetUnit(unit)
    currentUnit = unit
    currentGUID = unit and Units.GUID(unit) or nil
    if unit and not currentGUID then currentUnit = nil end
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
