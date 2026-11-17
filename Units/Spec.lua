-- Pardona's ToolTips - talent specialization of players ("Arms (31/20/0)").
--
-- Two sources:
--
-- 1. Talent tab API of the Classic talent trees: GetNumTalentTabs(isInspect) and
--    GetTalentTabInfo(tab, isInspect). Own character: isInspect = false. Other players:
--    isInspect = true, read while the inspect data of our own request is present (see
--    Units/ItemLevel.lua, which shares one inspect request for item level and spec).
--    GetTalentTabInfo returns either (name, icon, pointsSpent, ...) on old clients or
--    (id, name, description, icon, pointsSpent, ...) on newer ones; both are handled.
--
-- 2. Own character only, when the tab API gives the tree names but no spent points (the
--    WoW Forever client builds its talents on C_Traits, one trait tree per class):
--    the nodes of the active config are read through C_Traits and their purchased ranks
--    are summed per tree.
--    ASSUMPTION (not documented by the game): the classic trees are laid out side by
--    side, in tab order from left to right, and equally wide. The nodes are therefore
--    split by posX into as many equally wide columns between the smallest and the
--    largest posX as there are tabs (normally three). If the layout differs, the points
--    per tree are wrong; /ptt debug prints the raw values to check this.
--
-- Other players are only read through the tab API; without spent points there is no line.
-- Every API is read through _G or checked before use; anything missing means no line.

local _, ns = ...
local L = ns.L
local S = ns.Secret

local Spec = {}
ns.Spec = Spec

local MAX_TABS = 5          -- safety limit for the tab loop
local MAX_NODES = 2000      -- safety limit for the node loop
local CACHE_SECONDS = 10    -- own spec is cached this long unless talents change

local floor = math.floor

local function API()
    local numTabs, tabInfo = _G.GetNumTalentTabs, _G.GetTalentTabInfo
    if type(numTabs) ~= "function" or type(tabInfo) ~= "function" then return nil end
    return numTabs, tabInfo
end

-- True when the client offers the talent tab API.
function Spec.Available()
    return API() ~= nil
end

-- Number of talent tabs (1..MAX_TABS) or nil.
local function TabCount(isInspect)
    local numTabs = API()
    if not numTabs then return nil end
    local count = S.Number(S.CallClean(numTabs, isInspect))
    if not count or count < 1 then return nil end
    if count > MAX_TABS then count = MAX_TABS end
    return count
end

-- Name and spent points of one tab; each may be nil.
local function TabInfo(tab, isInspect)
    local _, tabInfo = API()
    local a, b, c, _, e = S.CallClean(tabInfo, tab, isInspect)
    if type(a) == "string" then
        -- Old layout: name, icon, pointsSpent
        return a, S.Number(c)
    end
    return S.String(b), S.Number(e)
end

-- "Arms (31/20/0)" or "Arms/Fury (20/20/11)" from names and points; nil without points.
local function Compose(names, points)
    local best, total = 0, 0
    for tab = 1, #points do
        total = total + points[tab]
        if points[tab] > best then best = points[tab] end
    end
    if total <= 0 then return nil end
    local leaders = {}
    for tab = 1, #points do
        if points[tab] == best then leaders[#leaders + 1] = names[tab] end
    end
    return L.SPEC_FORMAT:format(table.concat(leaders, "/"), table.concat(points, "/"))
end

---------------------------------------------------------------------------
-- C_Traits (own character)
---------------------------------------------------------------------------

local function ActiveConfigID()
    local classTalents = S.Table(_G.C_ClassTalents)
    if not classTalents then return nil end
    return S.Number(S.CallClean(classTalents.GetActiveConfigID))
end

-- Reads the nodes of the active trait config. Returns a table (fields may be nil):
--   configID, treeIDs (list), nodes (count), minX, maxX, minY, maxY,
--   purchased (sum of ranksPurchased), active (sum of activeRank), ranked (nodes with a
--   purchased rank > 0), list ({ x, rank } per node with readable posX)
-- or nil when C_Traits or the config is not available.
function Spec.TraitsScan()
    local traits = S.Table(C_Traits)
    if not traits or type(traits.GetTreeNodes) ~= "function"
        or type(traits.GetNodeInfo) ~= "function" then
        return nil
    end
    local configID = ActiveConfigID()
    if not configID then return nil end
    local scan = { configID = configID, treeIDs = {}, nodes = 0, purchased = 0, active = 0,
        ranked = 0, list = {} }

    local config = S.Table(S.CallClean(traits.GetConfigInfo, configID))
    local treeIDs = config and S.Table(S.Field(config, "treeIDs"))
    if not treeIDs then return scan end
    for i = 1, #treeIDs do
        local treeID = S.Number(treeIDs[i])
        if treeID then scan.treeIDs[#scan.treeIDs + 1] = treeID end
    end

    for _, treeID in ipairs(scan.treeIDs) do
        local nodeIDs = S.Table(S.CallClean(traits.GetTreeNodes, treeID))
        if nodeIDs then
            for i = 1, #nodeIDs do
                if scan.nodes >= MAX_NODES then break end
                local nodeID = S.Number(nodeIDs[i])
                local info = nodeID and S.Table(S.CallClean(traits.GetNodeInfo, configID, nodeID))
                if info then
                    scan.nodes = scan.nodes + 1
                    local x = S.Number(S.Field(info, "posX"))
                    local y = S.Number(S.Field(info, "posY"))
                    local purchased = S.Number(S.Field(info, "ranksPurchased"))
                    local active = S.Number(S.Field(info, "activeRank"))
                    if x then
                        if not scan.minX or x < scan.minX then scan.minX = x end
                        if not scan.maxX or x > scan.maxX then scan.maxX = x end
                        scan.list[#scan.list + 1] = { x = x, rank = purchased or 0 }
                    end
                    if y then
                        if not scan.minY or y < scan.minY then scan.minY = y end
                        if not scan.maxY or y > scan.maxY then scan.maxY = y end
                    end
                    if purchased then
                        scan.purchased = scan.purchased + purchased
                        if purchased > 0 then scan.ranked = scan.ranked + 1 end
                    end
                    if active then scan.active = scan.active + active end
                end
            end
        end
    end
    return scan
end

-- Points per tree from the trait nodes, split by posX into `count` equally wide
-- columns (see the assumption at the top of the file). nil when not possible.
local function TraitPoints(count)
    local scan = Spec.TraitsScan()
    if not scan or not scan.minX or not scan.maxX or scan.maxX <= scan.minX then return nil end
    local width = (scan.maxX - scan.minX) / count
    local points = {}
    for tab = 1, count do points[tab] = 0 end
    for _, node in ipairs(scan.list) do
        if node.rank > 0 then
            local column = floor((node.x - scan.minX) / width) + 1
            if column > count then column = count end
            points[column] = points[column] + node.rank
        end
    end
    return points
end

---------------------------------------------------------------------------
-- Spec text
---------------------------------------------------------------------------

local function Compute(isInspect)
    local count = TabCount(isInspect)
    if not count then return nil end

    local names, points, allPoints = {}, {}, true
    for tab = 1, count do
        local name, spent = TabInfo(tab, isInspect)
        if not name then return nil end
        names[tab] = name
        points[tab] = spent
        if not spent then allPoints = false end
    end

    if allPoints then
        local text = Compose(names, points)
        if text or isInspect then return text end
    elseif isInspect then
        return nil
    end

    -- Own character without spent points from the tab API: try C_Traits.
    if count < 2 then return nil end
    local traitPoints = TraitPoints(count)
    if not traitPoints then return nil end
    return Compose(names, traitPoints)
end

local cachedText, cachedAt -- own spec (false = nothing to show)

-- Spec text, for example "Arms (31/20/0)" or "Arms/Fury (20/20/11)". nil when the API
-- is missing, a value is not readable or no points are spent.
function Spec.Text(isInspect)
    if isInspect then return Compute(true) end
    local now = GetTime()
    if cachedAt and now - cachedAt < CACHE_SECONDS then
        return cachedText or nil
    end
    cachedText = Compute(false) or false
    cachedAt = now
    return cachedText or nil
end

-- Own talents changed (or /ptt debug wants fresh values): compute again on next use.
function Spec.Invalidate()
    cachedAt = nil
end

ns.On("TRAIT_CONFIG_UPDATED", Spec.Invalidate)
ns.On("PLAYER_TALENT_UPDATE", Spec.Invalidate)
ns.On("CHARACTER_POINTS_CHANGED", Spec.Invalidate)
