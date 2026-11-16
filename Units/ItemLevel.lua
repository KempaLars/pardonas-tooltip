-- Pardona's ToolTips - average item level of players and the shared inspect queue.
--
-- Own character: computed directly from the equipped items.
-- Other players: one inspect request at a time, only out of combat, only when
-- CanInspect allows it and the player is in inspect range, at most one request every
-- 1.5 s. One request serves both the item level and the spec (Units/Spec.lua); the
-- result { level, spec } is cached per GUID for 10 minutes. ClearInspectPlayer is only
-- called for requests this addon made, so other addons and the inspect window are
-- not disturbed.
--
-- Average: equipped slots 1-3 and 5-18 (shirt and tabard excluded), divided by 17.
-- A two-handed weapon with an empty off-hand counts twice.

local _, ns = ...
local S = ns.Secret
local Units = ns.Units
local Spec = ns.Spec

local ItemLevel = {}
ns.ItemLevel = ItemLevel

local SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local SLOT_MAIN_HAND, SLOT_OFF_HAND = 16, 17
local SLOT_COUNT = #SLOTS

local REQUEST_INTERVAL = 1.5   -- seconds between two inspect requests
local REQUEST_TIMEOUT  = 5     -- give up on an unanswered request after this time
local CACHE_SECONDS    = 600   -- keep results for 10 minutes
local RETRY_DELAY      = 0.5   -- item data of inspected players may arrive late
local MAX_RETRIES      = 3

local cache = {}            -- guid -> { level = number|nil, spec = string|nil, time = GetTime() }
local lastRequest = -math.huge
local pending               -- { guid, unit, time } of our open request
local listeners = {}        -- fn(guid, entry), called when a new result is cached

---------------------------------------------------------------------------
-- Calculation
---------------------------------------------------------------------------
local function SlotLevel(unit, slot)
    local itemID = S.Number(S.CallClean(GetInventoryItemID, unit, slot))
    if not itemID then return nil, false end            -- empty slot
    local link = S.String(S.CallClean(GetInventoryItemLink, unit, slot))
    if not link or type(C_Item) ~= "table" then return nil, true end -- item data not there yet
    local level = S.Number(S.CallClean(C_Item.GetDetailedItemLevelInfo, link))
    if not level then return nil, true end
    return level, false, link
end

local function IsTwoHand(link)
    if not link or type(C_Item) ~= "table" then return false end
    local _, _, _, equipLoc = S.CallClean(C_Item.GetItemInfoInstant, link)
    return S.String(equipLoc) == "INVTYPE_2HWEAPON"
end

-- Average item level of unit, or nil when any equipped item is not readable yet.
function ItemLevel.Compute(unit)
    local total, mainHandLevel, mainHandLink, offHandEmpty = 0, nil, nil, true
    local anyItem = false
    for i = 1, SLOT_COUNT do
        local slot = SLOTS[i]
        local level, missing, link = SlotLevel(unit, slot)
        if missing then return nil end
        if level then
            anyItem = true
            total = total + level
            if slot == SLOT_MAIN_HAND then mainHandLevel, mainHandLink = level, link end
            if slot == SLOT_OFF_HAND then offHandEmpty = false end
        end
    end
    if not anyItem then return nil end
    if mainHandLevel and offHandEmpty and IsTwoHand(mainHandLink) then
        total = total + mainHandLevel
    end
    return total / SLOT_COUNT
end

---------------------------------------------------------------------------
-- Cache
---------------------------------------------------------------------------

-- Cached inspect result { level, spec } of guid (either field may be nil), or nil.
function ItemLevel.Cached(guid)
    if not guid then return nil end
    local entry = cache[guid]
    if not entry then return nil end
    if GetTime() - entry.time > CACHE_SECONDS then
        cache[guid] = nil
        return nil
    end
    return entry
end

-- fn(guid, entry) is called whenever a new inspect result is cached.
function ItemLevel.OnResult(fn)
    listeners[#listeners + 1] = fn
end

local function Store(guid, level, spec)
    local entry = { level = level, spec = spec, time = GetTime() }
    cache[guid] = entry
    for i = 1, #listeners do
        local ok, err = pcall(listeners[i], guid, entry)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
        end
    end
end

---------------------------------------------------------------------------
-- Inspect requests
---------------------------------------------------------------------------

-- Blizzard's inspect window is load-on-demand; read through _G because it may not exist.
local function InspectWindowShown()
    local frame = _G.InspectFrame
    if frame == nil or not S.FrameUsable(frame) then return false end
    return S.Method(frame, "IsShown") == true
end

local function CanRequest(unit)
    if InCombatLockdown() then return false end
    if InspectWindowShown() then return false end
    if S.CallClean(CanInspect, unit) ~= true then return false end
    -- Distance index 1 = inspect range.
    if S.CallClean(CheckInteractDistance, unit, 1) ~= true then return false end
    return true
end

-- Requests item level and spec of another player if allowed. The result arrives later
-- through the listeners registered with ItemLevel.OnResult.
function ItemLevel.Request(unit, guid)
    if not unit or not guid or ItemLevel.Cached(guid) then return end
    local now = GetTime()
    if pending and now - pending.time > REQUEST_TIMEOUT then pending = nil end
    if pending or now - lastRequest < REQUEST_INTERVAL then return end
    if not CanRequest(unit) then return end

    local ok = pcall(NotifyInspect, unit)
    if not ok then return end
    lastRequest = now
    pending = { guid = guid, unit = unit, time = now }
end

-- Finds a unit token that currently points to guid.
local function UnitForGUID(guid, preferred)
    local candidates = { preferred, "mouseover", "target", "focus" }
    for i = 1, #candidates do
        local unit = candidates[i]
        if unit and Units.GUID(unit) == guid then return unit end
    end
    return nil
end

local function Finish()
    pending = nil
    if not InspectWindowShown() then pcall(ClearInspectPlayer) end
end

local function Evaluate(guid, attempt)
    if not pending or pending.guid ~= guid then return end
    local unit = UnitForGUID(guid, pending.unit)
    if not unit then
        Finish()
        return
    end
    -- Both are read while the inspect data of our request is present (before Finish).
    local level = ItemLevel.Compute(unit)
    local spec = Spec.Text(true)
    if level then
        Finish()
        Store(guid, level, spec)
    elseif attempt < MAX_RETRIES then
        C_Timer.After(RETRY_DELAY, function() Evaluate(guid, attempt + 1) end)
    else
        Finish()
        if spec then Store(guid, nil, spec) end
    end
end

ns.On("INSPECT_READY", function(_, guid)
    guid = S.String(guid)
    if not guid or not pending or pending.guid ~= guid then return end
    Evaluate(guid, 0)
end)
