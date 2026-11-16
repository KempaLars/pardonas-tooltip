-- Pardona's ToolTips - core: namespace, chat output, event dispatch and lifecycle.
-- Modules register with ns.OnLoad (after SavedVariables are available) and
-- ns.OnLogin (once the player is in the world). Queues run in TOC file order.

local ADDON_NAME, ns = ...
local L = ns.L

ns.ADDON_NAME = ADDON_NAME

---------------------------------------------------------------------------
-- Chat output
---------------------------------------------------------------------------
local PREFIX_COLOR = "ffd4af37" -- Pardona gold

function ns.Print(msg)
    print(("|c%s%s:|r %s"):format(PREFIX_COLOR, L.TITLE, tostring(msg)))
end

---------------------------------------------------------------------------
-- Event dispatch
---------------------------------------------------------------------------
local handlers = {}
local eventFrame = CreateFrame("Frame")

local function ReportError(err)
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler(err) end
end

local skippedEvents = {}  -- event names the client does not know

-- False when the client says the event does not exist, true when it exists, nil when
-- the client cannot tell (C_EventUtils.IsEventValid missing).
local function EventValid(event)
    local utils = C_EventUtils
    if type(utils) ~= "table" or type(utils.IsEventValid) ~= "function" then return nil end
    local ok, valid = pcall(utils.IsEventValid, event)
    if not ok then return nil end
    return valid == true
end

-- Registers fn(event, ...) for a game event. Errors in one handler do not stop the others.
-- Event names depend on the client version: an event the client does not know is
-- skipped silently (no error, no chat text) and listed by /ptt debug.
-- This is the only place that registers events; modules always go through ns.On.
function ns.On(event, fn)
    if skippedEvents[event] then return false end
    local list = handlers[event]
    if not list then
        if EventValid(event) == false
            or not pcall(eventFrame.RegisterEvent, eventFrame, event) then
            skippedEvents[event] = true
            return false
        end
        list = {}
        handlers[event] = list
    end
    list[#list + 1] = fn
    return true
end

-- Sorted names of the events that were skipped because the client does not know them.
function ns.SkippedEvents()
    local names = {}
    for event in pairs(skippedEvents) do names[#names + 1] = event end
    table.sort(names)
    return names
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], event, ...)
        if not ok then ReportError(err) end
    end
end)

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
local loadQueue, loginQueue, combatQueue = {}, {}, {}
local loaded, loggedIn = false, false

local function RunQueue(queue)
    for i = 1, #queue do
        local ok, err = pcall(queue[i])
        if not ok then ReportError(err) end
    end
end

-- fn runs once when our SavedVariables are loaded.
function ns.OnLoad(fn)
    if loaded then fn() else loadQueue[#loadQueue + 1] = fn end
end

-- fn runs once when the player has entered the world.
function ns.OnLogin(fn)
    if loggedIn then fn() else loginQueue[#loginQueue + 1] = fn end
end

-- fn runs now outside of combat, otherwise once combat ends. A key replaces an earlier entry.
function ns.RunOutOfCombat(key, fn)
    if not InCombatLockdown() then
        fn()
        return true
    end
    combatQueue[key] = fn
    return false
end

ns.On("ADDON_LOADED", function(_, name)
    if name ~= ADDON_NAME or loaded then return end
    loaded = true
    RunQueue(loadQueue)
    -- Loaded after login (for example on demand): run the login queue as well.
    if IsLoggedIn and IsLoggedIn() and not loggedIn then
        loggedIn = true
        RunQueue(loginQueue)
    end
end)

ns.On("PLAYER_LOGIN", function()
    if loggedIn then return end
    loggedIn = true
    RunQueue(loginQueue)
end)

ns.On("PLAYER_REGEN_ENABLED", function()
    local pending = combatQueue
    combatQueue = {}
    for _, fn in pairs(pending) do
        local ok, err = pcall(fn)
        if not ok then ReportError(err) end
    end
end)
