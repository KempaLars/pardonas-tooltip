-- Pardona's ToolTips - player and mob information on unit tooltips.
--
-- Blizzard lines are kept. Existing lines are only recolored (when their text is not
-- secret); our own lines are appended at the bottom with AddLine/AddDoubleLine in this
-- order: classification (only if the level line could not be used), target, speed,
-- item level, spec. Every line whose values are secret is left out silently. Health
-- text and resource bar are drawn on bars below the tooltip (HealthText, PowerBar).
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
local PowerBar = ns.PowerBar
local ItemLevel = ns.ItemLevel
local Spec = ns.Spec

local UnitInfo = {}
ns.UnitInfo = UnitInfo

local BASE_RUN_SPEED = 7       -- yards per second at 100 % run speed
local SPEED_INTERVAL = 0.2     -- seconds between live speed updates

-- Classification -> locale key of our tag, text color role and the words the client may
-- already write into the level line. Each word lists Blizzard global strings (read
-- through _G, may be missing) that may hold it, and the locale key of our tag for just
-- that word; the tag without its brackets (for example "Rare" from "(Rare)") counts as
-- a spelling of the word as well.
-- Rare elite is checked as its two words, because the client has no own global string
-- for it. RARE is missing in the WoW Forever client, so rare also accepts
-- ITEM_QUALITY3_DESC (item quality "Rare"; in German "Selten", which only matches if the
-- client writes that word).
local WORD_RARE  = { globals = { "RARE", "ITEM_QUALITY3_DESC" }, tag = "CLASS_RARE" }
local WORD_ELITE = { globals = { "ELITE" }, tag = "CLASS_ELITE" }
local WORD_BOSS  = { globals = { "BOSS" },  tag = "CLASS_BOSS" }

local CLASSIFICATIONS = {
    worldboss = { text = "CLASS_BOSS",      role = "elite", words = { WORD_BOSS } },
    rareelite = { text = "CLASS_RAREELITE", role = "rare",  words = { WORD_RARE, WORD_ELITE } },
    elite     = { text = "CLASS_ELITE",     role = "elite", words = { WORD_ELITE } },
    rare      = { text = "CLASS_RARE",      role = "rare",  words = { WORD_RARE } },
}

-- State of the unit GameTooltip currently shows (nil when none).
-- { unit (token used for reading; "target" when the unit is the player's target),
--   source (token of the tooltip), guid (may be nil), speedLine, itemLevelShown, specShown }
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

-- True when byte b belongs to a word (ASCII letter or digit, or part of a UTF-8 letter).
local function IsWordByte(b)
    if not b then return false end
    return b >= 128 or (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
end

-- Position of word in text as a whole word (plain search, no patterns built from game
-- text). Returns first, last; "ambiguous" when it occurs more than once; nil when absent.
local function FindWord(text, word)
    local found
    local start = 1
    while true do
        local first, last = text:find(word, start, true)
        if not first then break end
        if not IsWordByte(text:byte(first - 1)) and not IsWordByte(text:byte(last + 1)) then
            if found then return "ambiguous" end
            found = { first, last }
        end
        start = last + 1
    end
    if not found then return nil end
    return found[1], found[2]
end

-- Spellings of a word entry: its global strings and our tag without brackets, without
-- duplicates and empty or secret values.
local function WordSpellings(word)
    local list, seen = {}, {}
    local function Add(text)
        if text and text ~= "" and not seen[text] then
            seen[text] = true
            list[#list + 1] = text
        end
    end
    for _, name in ipairs(word.globals) do
        Add(S.String(_G[name]))
    end
    local tag = S.String(L[word.tag])
    if tag then Add(tag:match("^%((.+)%)$") or tag) end
    return list
end

-- Finds a word entry in the level line. Returns "done" when one spelling is already
-- colored by us, first, last of the single whole-word occurrence, "ambiguous" when a
-- spelling occurs more than once, or nil when no spelling occurs.
local function FindClassWord(lineText, word, role)
    -- Our own tag for this word was appended earlier (tooltip refreshed). Checked first,
    -- because the bare spelling ("Rare") would otherwise match inside "(Rare)".
    if lineText:find(ColorSets.Colorize(role, L[word.tag]), 1, true) then return "done" end
    local found, foundLast
    for _, spelling in ipairs(WordSpellings(word)) do
        if lineText:find(ColorSets.Colorize(role, spelling), 1, true) then return "done" end
        local first, last = FindWord(lineText, spelling)
        if first == "ambiguous" then return "ambiguous" end
        if first then
            -- Two different spellings found at different places: ambiguous.
            if found and found ~= first then return "ambiguous" end
            found, foundLast = first, last
        end
    end
    return found, foundLast
end

-- Handles the level line text for a classification entry. Returns the new text, or
-- nil to leave the line unchanged.
--   * Words the client already wrote are colored in the set color (each must occur
--     exactly once as a whole word; already colored by us counts as done).
--   * Words it did not write are appended as our tags, for example "(Elite)".
--   * Anything ambiguous: line unchanged.
local function ClassifiedLevelText(lineText, entry)
    local missing, ranges = {}, {}
    for _, word in ipairs(entry.words) do
        local first, last = FindClassWord(lineText, word, entry.role)
        if first == "ambiguous" then return nil end
        if first == nil then
            missing[#missing + 1] = word
        elseif first ~= "done" then
            ranges[#ranges + 1] = { first, last }
        end
    end

    -- Our full tag already present (tooltip refreshed): nothing to do.
    local fullTag = ColorSets.Colorize(entry.role, L[entry.text])
    if lineText:find(fullTag, 1, true) then return nil end

    -- Color the found words, from the back so earlier positions stay valid.
    table.sort(ranges, function(a, b) return a[1] > b[1] end)
    local text = lineText
    for _, range in ipairs(ranges) do
        local first, last = range[1], range[2]
        text = text:sub(1, first - 1) .. ColorSets.Colorize(entry.role, text:sub(first, last))
            .. text:sub(last + 1)
    end

    if #missing == #entry.words then
        text = text .. " " .. fullTag
    else
        for _, word in ipairs(missing) do
            local tag = ColorSets.Colorize(entry.role, L[word.tag])
            if not text:find(tag, 1, true) then text = text .. " " .. tag end
        end
    end
    if text == lineText then return nil end
    return text
end

-- Marks the classification on the level line: colors it when the client already wrote
-- it, otherwise appends our tag. Returns the colored tag when it has to go into an own
-- line instead (no level line found), nil when done or nothing to show.
local function MarkClassification(tooltip, unit)
    local classification = S.String(S.CallClean(UnitClassification, unit))
    local entry = classification and CLASSIFICATIONS[classification]
    if not entry then return nil end

    local prefix = LevelPrefix()
    if prefix then
        for i = 2, Units.NumLines(tooltip) do
            local fontString = Units.Line(tooltip, "Left", i)
            -- A secret line could be the level line: then change nothing at all, an own
            -- line might repeat what the client already wrote.
            if fontString and S.IsSecret(S.Call(fontString.GetText, fontString)) then
                return nil
            end
            local lineText = Units.LineText(fontString)
            if lineText and lineText:sub(1, #prefix) == prefix then
                local text = ClassifiedLevelText(lineText, entry)
                if text then S.Method(fontString, "SetText", text) end
                return nil
            end
        end
    end
    return ColorSets.Colorize(entry.role, L[entry.text])
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

    local source = Units.Resolve(tooltip, data)
    if not source then
        HealthText.SetUnit(nil)
        PowerBar.SetUnit(nil)
        return
    end
    -- When the unit is also the player's target, read it through "target".
    local unit = Units.PreferTarget(source)
    current = { unit = unit, source = source, guid = Units.GUID(unit) }
    HealthText.SetUnit(unit)
    PowerBar.SetUnit(unit)

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

-- The player changed target while the tooltip reads its unit through "target": go back
-- to the tooltip's own token, so health and speed keep following the right unit.
local function OnTargetChanged()
    if not current or current.unit ~= "target" or current.source == "target" then return end
    current.unit = current.source
    HealthText.SetUnit(current.source)
    PowerBar.SetUnit(current.source)
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

ns.On("PLAYER_TARGET_CHANGED", OnTargetChanged)
