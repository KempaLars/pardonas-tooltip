-- Pardona's ToolTips - talent specialization of players ("Arms (31/20/0)").
--
-- Uses the talent tab API of the Classic talent trees: GetNumTalentTabs(isInspect) and
-- GetTalentTabInfo(tab, isInspect). Own character: isInspect = false. Other players:
-- isInspect = true, read while the inspect data of our own request is present (see
-- Units/ItemLevel.lua, which shares one inspect request for item level and spec).
--
-- Both functions are read through _G: the WoW Forever client builds its talents on
-- C_Traits and may not offer the tab API at all. Without it no spec line is shown.
--
-- GetTalentTabInfo returns either (name, icon, pointsSpent, ...) on old clients or
-- (id, name, description, icon, pointsSpent, ...) on newer ones; both are handled.

local _, ns = ...
local L = ns.L
local S = ns.Secret

local Spec = {}
ns.Spec = Spec

local MAX_TABS = 5          -- safety limit for the tab loop

local function API()
    local numTabs, tabInfo = _G.GetNumTalentTabs, _G.GetTalentTabInfo
    if type(numTabs) ~= "function" or type(tabInfo) ~= "function" then return nil end
    return numTabs, tabInfo
end

-- True when the client offers the talent tab API.
function Spec.Available()
    return API() ~= nil
end

-- Name and spent points of one tab, or nil.
local function TabInfo(tabInfo, tab, isInspect)
    local a, b, c, _, e = S.CallClean(tabInfo, tab, isInspect)
    if type(a) == "string" then
        -- Old layout: name, icon, pointsSpent
        return a, S.Number(c)
    end
    return S.String(b), S.Number(e)
end

-- Spec text, for example "Arms (31/20/0)" or "Arms/Fury (20/20/11)". nil when the API
-- is missing, a value is not readable or no points are spent.
function Spec.Text(isInspect)
    local numTabs, tabInfo = API()
    if not numTabs then return nil end
    local count = S.Number(S.CallClean(numTabs, isInspect))
    if not count or count < 1 then return nil end
    if count > MAX_TABS then count = MAX_TABS end

    local names, points, best, total = {}, {}, 0, 0
    for tab = 1, count do
        local name, spent = TabInfo(tabInfo, tab, isInspect)
        if not name or not spent then return nil end
        names[tab], points[tab] = name, spent
        total = total + spent
        if spent > best then best = spent end
    end
    if total <= 0 then return nil end

    local leaders = {}
    for tab = 1, count do
        if points[tab] == best then leaders[#leaders + 1] = names[tab] end
    end
    return L.SPEC_FORMAT:format(table.concat(leaders, "/"), table.concat(points, "/"))
end
