-- Pardona's ToolTips - Enchanting skill of the character.
--
-- WoW Forever reads skill lines through C_SkillInfo. Preferred is
-- C_SkillInfo.GetSkillLineInfoByID(333) (333 = Enchanting skill line); it returns a table
-- with name and rank. Fallback: walk the skill lines (C_SkillInfo.GetSkillLineInfo or the
-- older global GetSkillLineInfo) and match the localized Enchanting name.
-- The result is cached and refreshed on SKILL_LINES_CHANGED and at login.

local _, ns = ...
local S = ns.Secret

local Professions = {}
ns.Professions = Professions

local ENCHANTING_SKILL_LINE = 333
local ENCHANTING_SPELL = 7411      -- "Enchanting" (Apprentice), only used for its localized name

local enchanting                  -- cached rank: number (0 = not learned) or nil (unknown)
local dirty = true

local function RankFromInfo(info)
    info = S.Table(info)
    if not info then return nil end
    return S.Number(S.Field(info, "rank")) or S.Number(S.Field(info, "skillRank"))
end

local function ByID()
    local api = S.Table(C_SkillInfo)
    if not api or type(api.GetSkillLineInfoByID) ~= "function" then return nil end
    local ok, info = pcall(api.GetSkillLineInfoByID, ENCHANTING_SKILL_LINE)
    if not ok or S.IsSecret(info) then return nil end
    if info == nil then return 0 end -- the call worked, the skill is just not learned
    return RankFromInfo(info)
end

local function EnchantingName()
    local spell = S.Table(C_Spell)
    if not spell then return nil end
    return S.String(S.CallClean(spell.GetSpellName, ENCHANTING_SPELL))
end

local function BySkillLines()
    local name = EnchantingName()
    if not name then return nil end
    local api = S.Table(C_SkillInfo)
    local getCount = (api and api.GetNumSkillLines) or _G.GetNumSkillLines
    local getInfo = (api and api.GetSkillLineInfo) or _G.GetSkillLineInfo
    if type(getCount) ~= "function" or type(getInfo) ~= "function" then return nil end
    local count = S.Number(S.CallClean(getCount))
    if not count then return nil end
    for i = 1, count do
        local first, _, _, rank = S.CallClean(getInfo, i)
        local lineName, lineRank
        if type(first) == "table" then
            lineName, lineRank = S.String(S.Field(first, "name")), RankFromInfo(first)
        else
            lineName, lineRank = S.String(first), S.Number(rank)
        end
        if lineName == name then return lineRank or 0 end
    end
    return 0
end

local function Refresh()
    local rank = ByID()
    if rank == nil then rank = BySkillLines() end
    enchanting = rank
    dirty = false
end

-- Enchanting skill rank: number (0 = not learned) or nil when it cannot be determined.
function Professions.EnchantingRank()
    if dirty then Refresh() end
    return enchanting
end

-- True when the character has learned Enchanting (unknown counts as not learned).
function Professions.KnowsEnchanting()
    local rank = Professions.EnchantingRank()
    return rank ~= nil and rank > 0
end

local function MarkDirty()
    dirty = true
end

ns.On("SKILL_LINES_CHANGED", MarkDirty)
ns.On("LEARNED_SPELL_IN_TAB", MarkDirty)
ns.OnLogin(MarkDirty)
