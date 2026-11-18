-- Pardona's ToolTips - SavedVariables: defaults, validation and migrations.
-- The SavedVariables name PardonasToolTipsDB must never change.

local _, ns = ...

local Database = {}
ns.Database = Database

-- Current layout of PardonasToolTipsDB. Raise it together with a new migration.
local DB_VERSION = 1

ns.DEFAULTS = {
    version        = DB_VERSION,
    -- Appearance
    position       = "cursor",
    offset         = 20,
    scale          = 100,
    font           = "builtin:friz",
    fontSizeHeader = 14,
    fontSizeText   = 12,
    colorSet       = "pardona", -- new installs and resets; saved choices are kept
    colorBorder    = true,
    -- Players & mobs (added in 0.1.0 without migration: missing fields get defaults)
    unitNameClassColor = true,
    unitGuildColor     = true,
    unitClassLineColor = true,
    unitHealthText     = true,
    unitTarget         = true,
    unitSpeed          = true,
    unitMana           = true,  -- main resource line (name kept for saved settings)
    unitItemLevel      = true,
    unitSpec           = true,
    unitClassification = true,
    -- Experimental features: "auto" (on in dev and beta builds, off in release builds),
    -- "on" or "off". Added without migration: a missing field gets the default.
    experimental       = "auto",
    -- Items (added without migration: missing fields get defaults)
    itemLevel          = true,
    itemCompare        = "always", -- "always", "shift" or "off"
    itemHideAppearance = true,
    -- Prices & disenchanting (added without migration: missing fields get defaults)
    deChances          = true,
    deValue            = true,
    deRecommend        = true,
    ahFee              = 5,     -- percent
    minSaleRate        = 0.10,
    minSoldPerDay      = 0.5,
    -- Shared lib-pardona state (minimap button). The library owns the fields inside;
    -- added without migration: a missing table gets a new empty one.
    pardona            = {},
}

-- Valid ranges for numeric settings: { min, max, step }.
ns.LIMITS = {
    offset         = { 0, 200, 1 },
    scale          = { 50, 200, 5 },
    fontSizeHeader = { 8, 30, 1 },
    fontSizeText   = { 6, 24, 1 },
    ahFee          = { 0, 20, 1 },
    minSaleRate    = { 0, 1, 0.01 },
    minSoldPerDay  = { 0, 20, 0.1 },
}

-- Allowed values of string settings with a fixed choice. Any other value is replaced
-- by the default.
ns.CHOICES = {
    experimental = { auto = true, on = true, off = true },
}

-- migrations[n] upgrades a database of version n - 1 to version n.
-- Example for a later version:
--   migrations[2] = function(db) db.newField = db.oldField; db.oldField = nil end
local migrations = {}

-- Table defaults are copied so the saved table never shares ns.DEFAULTS.
local function CopyValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = CopyValue(v) end
    return copy
end

local function CopyDefaults(db)
    for key, value in pairs(ns.DEFAULTS) do
        if db[key] == nil or type(db[key]) ~= type(value) then
            db[key] = CopyValue(value)
        end
    end
end

local function Clamp(db)
    for key, range in pairs(ns.LIMITS) do
        local v = db[key]
        if type(v) == "number" then
            if v < range[1] then v = range[1] elseif v > range[2] then v = range[2] end
            db[key] = v
        end
    end
end

local function CheckChoices(db)
    for key, allowed in pairs(ns.CHOICES) do
        if not allowed[db[key]] then db[key] = ns.DEFAULTS[key] end
    end
end

local function Migrate(db)
    local from = type(db.version) == "number" and db.version or 0
    for v = from + 1, DB_VERSION do
        local step = migrations[v]
        if step then step(db) end
    end
    db.version = DB_VERSION
end

-- Brings db up to date: migrations first, then missing fields and ranges.
function Database.Prepare(db)
    Migrate(db)
    CopyDefaults(db)
    CheckChoices(db)
    Clamp(db)
end

-- Resets every setting to its default. The table identity is kept because the
-- options window holds a reference to it. The shared lib-pardona table is kept as well:
-- the library holds a reference to it, and the minimap button is shared by all Pardona
-- addons, so resetting this addon must not move or show it.
function Database.Reset()
    local db = ns.db
    if not db then return end
    local pardona = db.pardona
    wipe(db)
    if type(pardona) == "table" then db.pardona = pardona end
    CopyDefaults(db)
end

---------------------------------------------------------------------------
-- Build type and experimental features
---------------------------------------------------------------------------
local buildType -- cached once the version could be read

-- Build type from the TOC version: "dev" while it is still the packager placeholder
-- ("@project-version@" in a development checkout), "beta" when it contains "alpha" or
-- "beta" (any case), otherwise "release". An unreadable or secret version counts as
-- "release" and is not cached, so it is read again next time.
function ns.BuildType()
    if buildType then return buildType end
    local S = ns.Secret
    local addons = S.Table(C_AddOns)
    if not addons or type(addons.GetAddOnMetadata) ~= "function" then return "release" end
    local version = S.String(S.CallClean(addons.GetAddOnMetadata, ns.ADDON_NAME, "Version"))
    if not version then return "release" end
    local lower = version:lower()
    if version:sub(1, 1) == "@" then
        buildType = "dev"
    elseif lower:find("alpha", 1, true) or lower:find("beta", 1, true) then
        buildType = "beta"
    else
        buildType = "release"
    end
    return buildType
end

-- Effective state of the experimental features (true = on). "on" and "off" apply as
-- set, "auto" is on in dev and beta builds and off in release builds. Callers ask on
-- every tooltip, so a change applies without /reload.
function ns.IsExperimental()
    local db = ns.db
    local mode = db and db.experimental or ns.DEFAULTS.experimental
    if mode == "on" then return true end
    if mode == "off" then return false end
    return ns.BuildType() ~= "release"
end

ns.OnLoad(function()
    if type(PardonasToolTipsDB) ~= "table" then
        PardonasToolTipsDB = {}
    end
    Database.Prepare(PardonasToolTipsDB)
    ns.db = PardonasToolTipsDB
end)
