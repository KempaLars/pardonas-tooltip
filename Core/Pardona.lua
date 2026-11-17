-- Pardona's ToolTips - shared Pardona library (lib-pardona, LibPardona-1.0).
-- Registers the addon for the shared minimap button, the addon compartment entry, the
-- "Pardona's Addons" settings category and the LibDataBroker launcher. Only the public
-- API documented in the library's README is used.
-- The library is optional: without it (folder missing, LibStub missing) the addon works
-- as before, without an error and without chat text.
--
-- info.addon (LibPardona-1.0 MINOR 3 and later) is the folder name from the TOC
-- ("PardonasToolTips"). The library reads the version from it and loads its emblem
-- textures by convention from Interface\AddOns\<addon>\Libs\lib-pardona\..., so the
-- library must be embedded at exactly Libs\lib-pardona.

local ADDON, ns = ...
local L = ns.L

local Pardona = {}
ns.Pardona = Pardona

local LIB_NAME = "LibPardona-1.0"

-- Id of this addon inside the library (registration and settings subcategory).
Pardona.ID = "ToolTips"

local lib -- set once RegisterAddon succeeded

-- LibStub is read through _G: it only exists when lib-pardona (or another addon) loaded it.
local function FindLibrary()
    local libStub = _G.LibStub
    if libStub == nil then return nil end
    local ok, found = pcall(libStub, LIB_NAME, true)
    if ok and type(found) == "table" then return found end
    return nil
end

-- Short status for the minimap tooltip, the overview page and the broker text.
local function Status()
    if ns.Prices and ns.Prices.Available() then return L.STATUS_ACTIVE end
    return L.STATUS_ACTIVE_NO_TSM
end

-- The library object, or nil when it is not loaded or the registration failed.
function Pardona.Lib()
    return lib
end

-- /ptt minimap: shows or hides the shared button. False when the library is not loaded.
function Pardona.ToggleMinimap()
    if not lib then return false end
    lib:ToggleMinimap()
    return true
end

-- Runs after SavedVariables are loaded (Core\Database.lua comes first in the TOC), and
-- before Options\Options.lua builds the settings page.
ns.OnLoad(function()
    local LP = FindLibrary()
    if not LP or type(ns.db) ~= "table" or type(ns.db.pardona) ~= "table" then return end
    -- Opening goes through Options.Open: it uses LP:OpenSettings and waits for the end
    -- of combat, like /ptt.
    local ok, err = pcall(LP.RegisterAddon, LP, Pardona.ID, {
        name    = L.TITLE,
        addon   = ADDON,
        icon    = "Interface\\AddOns\\PardonasToolTips\\Textures\\Icon",
        db      = ns.db.pardona,
        onClick = function() ns.Options.Open() end,
        status  = Status,
    })
    if ok then
        lib = LP
    else
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(err) end
    end
end)
