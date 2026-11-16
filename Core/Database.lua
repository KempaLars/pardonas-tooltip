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
    colorSet       = "blizzard",
    colorBorder    = true,
    -- Players & mobs (added in 0.1.0 without migration: missing fields get defaults)
    unitNameClassColor = true,
    unitGuildColor     = true,
    unitClassLineColor = true,
    unitHealthText     = true,
    unitTarget         = true,
    unitSpeed          = true,
    unitMana           = true,
    unitItemLevel      = true,
    unitClassification = true,
}

-- Valid ranges for numeric settings: { min, max, step }.
ns.LIMITS = {
    offset         = { 0, 200, 1 },
    scale          = { 50, 200, 5 },
    fontSizeHeader = { 8, 30, 1 },
    fontSizeText   = { 6, 24, 1 },
}

-- migrations[n] upgrades a database of version n - 1 to version n.
-- Example for a later version:
--   migrations[2] = function(db) db.newField = db.oldField; db.oldField = nil end
local migrations = {}

local function CopyDefaults(db)
    for key, value in pairs(ns.DEFAULTS) do
        if db[key] == nil or type(db[key]) ~= type(value) then
            db[key] = value
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
    Clamp(db)
end

-- Resets every setting to its default. The table identity is kept because the
-- options window holds a reference to it.
function Database.Reset()
    local db = ns.db
    if not db then return end
    wipe(db)
    CopyDefaults(db)
end

ns.OnLoad(function()
    if type(PardonasToolTipsDB) ~= "table" then
        PardonasToolTipsDB = {}
    end
    Database.Prepare(PardonasToolTipsDB)
    ns.db = PardonasToolTipsDB
end)
