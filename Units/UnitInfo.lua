-- Pardona's ToolTips - player and mob information on unit tooltips.
--
-- Blizzard lines are kept. Existing lines are only recolored (when their text is not
-- secret); our own lines are appended at the bottom with AddLine/AddDoubleLine in this
-- order: classification (only if the level line could not be used), target, speed,
-- resource, item level, spec. Every line whose values are secret is left out silently.
--
-- The unit's GUID is optional. Without it everything that needs no cache still works;
-- item level and spec of other players (cached per GUID) are then skipped.

local _, ns = ...
local L = ns.L
local S = ns.Secret
local Units = ns.Units
local Format = ns.Format
local ColorSets = ns.ColorSets
local HealthText = ns.HealthText
local ItemLevel = ns.ItemLevel
local Spec = ns.Spec

local UnitInfo = {}
ns.UnitInfo = UnitInfo

local BASE_RUN_SPEED = 7       -- yards per second at 100 % run speed
local SPEED_INTERVAL = 0.2     -- seconds between live speed updates

-- Classification -> locale key and text color role.
local CLASSIFICATIONS = {
    worldboss = { text = "CLASS_BOSS",      role = "elite" },
    rareelite = { text = "CLASS_RAREELITE", role = "rare" },
    elite     = { text = "CLASS_ELITE",     role = "elite" },
    rare      = { text = "CLASS_RARE",      role = "rare" },
}

-- State of the unit GameTooltip currently shows (nil when none).
-- { unit, guid (may be nil), speedLine, itemLevelShown, specShown }
local current

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local AddPair = Units.AddPair

local function SetLineColor(fontString, color)
    if fontString and color then
        S.Method(fontString, "SetTextColor", color[1], color[2], color[3])
    end
end

local function SpeedText(unit)
    local speed = S.Number(S.CallClean(GetUnitSpeed, unit))
    if not speed then return nil end
    return Format.Percent(speed / BASE_RUN_SPEED * 100)
end

---------------------------------------------------------------------------
-- Recoloring Blizzard lines
---------------------------------------------------------------------------

-- Index of the guild line (or nil). Matches "Guild", "Guild - Rank" and "<Guild>".
local function FindGuildLine(tooltip, unit, numLines)
    local guild = S.String(S.CallClean(GetGuildInfo, unit))
    if not guild or guild == "" then return nil end
    for i = 2, numLines do
        local text = Units.LineText(Units.Line(tooltip, "Left", i))
        if text and (text:sub(1, #guild) == guild or text:sub(1, #guild + 1) == "<" .. guild) then
            return i
        end
    end
    return nil
end

local function RecolorClassLine(tooltip, numLines, skipLine, className, classColor)
    local colored = ColorSets.Escape(classColor[1], classColor[2], classColor[3]) .. className .. "|r"
    for i = 2, numLines do
        if i ~= skipLine then
            local fontString = Units.Line(tooltip, "Left", i)
            local text = Units.LineText(fontString)
            if text then
                if text == className then
                    SetLineColor(fontString, classColor)
                    return
                end
                local first, last = text:find(className, 1, true)
                if first then
                    if not text:find(colored, 1, true) then
                        S.Method(fontString, "SetText", text:sub(1, first - 1) .. colored .. text:sub(last + 1))
                    end
                    return
                end
            end
        end
    end
end

local function RecolorPlayer(tooltip, unit, db)
    local numLines = Units.NumLines(tooltip)
    local className, classFile = Units.Class(unit)
    local classColor = Units.ClassColor(classFile)

    if db.unitNameClassColor and classColor then
        local nameLine = Units.Line(tooltip, "Left", 1)
        if Units.LineText(nameLine) then SetLineColor(nameLine, classColor) end
    end

    local guildLine = FindGuildLine(tooltip, unit, numLines)
    if db.unitGuildColor and guildLine then
        SetLineColor(Units.Line(tooltip, "Left", guildLine), ColorSets.Role("guild"))
    end

    if db.unitClassLineColor and className and classColor then
        RecolorClassLine(tooltip, numLines, guildLine, className, classColor)
    end
end

-- Text before the level number in the level line, for example "Level " (enUS).
local function LevelPrefix()
    local pattern = S.String(TOOLTIP_UNIT_LEVEL)
    local prefix = pattern and pattern:match("^(.-)%%")
    if prefix and prefix:match("%S") then return prefix end
    return nil
end

-- Appends the classification to the level line. Returns the colored text when it has
-- to go into an own line instead, nil when done or nothing to show.
local function MarkClassification(tooltip, unit)
    local classification = S.String(S.CallClean(UnitClassification, unit))
    local entry = classification and CLASSIFICATIONS[classification]
    if not entry then return nil end
    local text = ColorSets.Colorize(entry.role, L[entry.text])

    local prefix = LevelPrefix()
    if prefix then
        for i = 2, Units.NumLines(tooltip) do
            local fontString = Units.Line(tooltip, "Left", i)
            local lineText = Units.LineText(fontString)
            if lineText and lineText:sub(1, #prefix) == prefix then
                if not lineText:find(text, 1, true) then
                    S.Method(fontString, "SetText", lineText .. " " .. text)
                end
                return nil
            end
        end
    end
    return text
end

---------------------------------------------------------------------------
-- Our lines
---------------------------------------------------------------------------
local function AddTarget(tooltip, unit)
    local target = unit .. "target"
    if Units.Exists(target) ~= true then return end
    local isSelf = Units.IsSelf(target)
    if isSelf == nil then return end
    if isSelf then
        AddPair(tooltip, L.LINE_TARGET, L.TARGET_YOU, ColorSets.Role("negative"))
        return
    end
    local name = Units.Name(target)
    if not name then return end
    AddPair(tooltip, L.LINE_TARGET, name, Units.Color(target))
end

local function AddSpeed(tooltip, unit)
    local text = SpeedText(unit)
    if not text then return nil end
    return AddPair(tooltip, L.LINE_SPEED, text)
end

-- Main resource with its localized name: "Energy: 100 / 100" or "Mana: 80%".
-- A secret percentage is left out: our line lives in a Blizzard tooltip line, and a
-- secret text there would make the line unreadable for other code.
local function AddResource(tooltip, unit)
    local grade, a, b, name = Units.Power(unit)
    local value
    if grade == "exact" then
        value = Format.Ratio(a, b)
    elseif grade == "percent" then
        value = Format.Percent(a)
    end
    if not value then return end
    AddPair(tooltip, L.LINE_RESOURCE:format(name), value)
end

-- Item level and spec: own character directly, other players from the inspect cache
-- (a request is made when nothing is cached). Sets current.itemLevelShown/specShown.
local function AddInspectLines(tooltip, unit, guid, db)
    local isSelf = Units.IsSelf(unit)
    local level, spec
    if isSelf == true then
        if db.unitItemLevel then level = ItemLevel.Compute("player") end
        if db.unitSpec then spec = Spec.Text(false) end
    elseif isSelf == false and guid then
        local entry = ItemLevel.Cached(guid)
        if entry then
            level, spec = entry.level, entry.spec
        else
            ItemLevel.Request(unit, guid)
        end
    end
    if db.unitItemLevel and level then
        AddPair(tooltip, L.LINE_ITEM_LEVEL, Format.Decimal(level, 1))
        current.itemLevelShown = true
    end
    if db.unitSpec and spec then
        AddPair(tooltip, L.LINE_SPEC, spec)
        current.specShown = true
    end
end

---------------------------------------------------------------------------
-- Live speed update (own frame, throttled; only changes the text of our line)
---------------------------------------------------------------------------
local ticker = CreateFrame("Frame")
ticker:Hide()
local elapsedSinceUpdate = 0

local function StopTicker()
    ticker:Hide()
end

-- True while GameTooltip still shows the unit in `current`. Without a readable GUID
-- the tooltip's OnHide and the next unit tooltip reset `current`.
local function SameUnitStillShown()
    if not current or S.Method(GameTooltip, "IsShown") ~= true then return false end
    if not current.guid then return true end
    return Units.GUID(current.unit) == current.guid
end

ticker:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < SPEED_INTERVAL then return end
    elapsedSinceUpdate = 0

    if not SameUnitStillShown() or not current.speedLine then
        self:Hide()
        return
    end
    local index = current.speedLine
    -- Only touch the line if it is still ours.
    if Units.LineText(Units.Line(GameTooltip, "Left", index)) ~= L.LINE_SPEED then
        self:Hide()
        return
    end
    local valueLine = Units.Line(GameTooltip, "Right", index)
    local text = SpeedText(current.unit)
    if not valueLine or not text then return end
    local old = Units.LineText(valueLine)
    if text ~= old then
        S.Method(valueLine, "SetText", text)
        -- Let the tooltip grow when the value got wider.
        if not old or #text > #old then S.Method(GameTooltip, "Show") end
    end
end)

local function StartTicker()
    elapsedSinceUpdate = 0
    ticker:Show()
end

---------------------------------------------------------------------------
-- Tooltip handling
---------------------------------------------------------------------------
local function OnUnitTooltip(tooltip, data)
    if S.IsSecret(tooltip) or tooltip ~= GameTooltip then return end
    local db = ns.db
    if not db then return end

    StopTicker()
    current = nil

    local unit = Units.Resolve(tooltip, data)
    if not unit then
        HealthText.SetUnit(nil)
        return
    end
    current = { unit = unit, guid = Units.GUID(unit) }
    HealthText.SetUnit(unit)

    local isPlayer = Units.IsPlayer(unit)
    local classificationLine
    if isPlayer == true then
        RecolorPlayer(tooltip, unit, db)
    elseif isPlayer == false and db.unitClassification then
        classificationLine = MarkClassification(tooltip, unit)
    end

    if classificationLine then S.Method(tooltip, "AddLine", classificationLine) end
    if db.unitTarget then AddTarget(tooltip, unit) end
    if db.unitSpeed then
        current.speedLine = AddSpeed(tooltip, unit)
        if current.speedLine then StartTicker() end
    end
    if db.unitMana then AddResource(tooltip, unit) end
    if isPlayer == true and (db.unitItemLevel or db.unitSpec) then
        AddInspectLines(tooltip, unit, current.guid, db)
    end
end

-- A late inspect result: add the missing lines if the tooltip still shows that player.
local function OnInspectResult(guid, entry)
    local db = ns.db
    if not db or not current or not current.guid or current.guid ~= guid then return end
    if not SameUnitStillShown() then return end
    local added = false
    if db.unitItemLevel and entry.level and not current.itemLevelShown then
        AddPair(GameTooltip, L.LINE_ITEM_LEVEL, Format.Decimal(entry.level, 1))
        current.itemLevelShown = true
        added = true
    end
    if db.unitSpec and entry.spec and not current.specShown then
        AddPair(GameTooltip, L.LINE_SPEC, entry.spec)
        current.specShown = true
        added = true
    end
    if added then S.Method(GameTooltip, "Show") end
end

local function OnTooltipHide()
    StopTicker()
    current = nil
end

ns.OnLoad(function()
    local processor = TooltipDataProcessor
    local types = S.Table(Enum) and S.Table(Enum.TooltipDataType)
    if type(processor) == "table" and type(processor.AddTooltipPostCall) == "function"
        and types and types.Unit then
        -- Protected, so an unexpected error never breaks Blizzard's tooltip processing.
        processor.AddTooltipPostCall(types.Unit, function(tooltip, data)
            local ok, err = pcall(OnUnitTooltip, tooltip, data)
            if not ok then
                local handler = geterrorhandler and geterrorhandler()
                if handler then handler(err) end
            end
        end)
    end
    if S.FrameUsable(GameTooltip) then
        pcall(GameTooltip.HookScript, GameTooltip, "OnHide", OnTooltipHide)
    end
    ItemLevel.OnResult(OnInspectResult)
end)
