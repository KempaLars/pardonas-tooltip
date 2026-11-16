-- Pardona's ToolTips - color sets.
--
-- All colors live in this file. To add a set: add an entry to SETS, append its key
-- to ORDER and add a localized name (L[set.name]) to every locale file.
--
-- Fields of a set:
--   name        locale key of the display name
--   background  { r, g, b } or nil to keep the Blizzard background
--   bgAlpha     background opacity 0..1 (used with background)
--   border      { r, g, b, a } or nil to keep the Blizzard border
--   text        colors for lines added by this addon: label, value, positive,
--               negative, guild, elite, rare, hint ({ r, g, b } each)

local _, ns = ...

local ColorSets = {}
ns.ColorSets = ColorSets

local DEFAULT_SET = "blizzard"

local ORDER = { "blizzard", "dark", "contrast", "pardona" }

local SETS = {
    blizzard = {
        name       = "SET_BLIZZARD",
        background = nil,
        bgAlpha    = nil,
        border     = nil,
        text = {
            label    = { 1.00, 0.82, 0.00 },
            value    = { 1.00, 1.00, 1.00 },
            positive = { 0.10, 1.00, 0.10 },
            negative = { 1.00, 0.13, 0.13 },
            guild    = { 0.25, 1.00, 0.25 },
            elite    = { 1.00, 0.82, 0.00 },
            rare     = { 0.78, 0.78, 0.78 },
            hint     = { 0.60, 0.60, 0.60 },
        },
    },
    dark = {
        name       = "SET_DARK",
        background = { 0.03, 0.03, 0.04 },
        bgAlpha    = 0.90,
        border     = { 0.40, 0.40, 0.40, 1.00 },
        text = {
            label    = { 0.75, 0.75, 0.75 },
            value    = { 1.00, 1.00, 1.00 },
            positive = { 0.35, 0.90, 0.35 },
            negative = { 0.95, 0.35, 0.35 },
            guild    = { 0.45, 0.85, 1.00 },
            elite    = { 1.00, 0.80, 0.30 },
            rare     = { 0.80, 0.80, 0.90 },
            hint     = { 0.55, 0.55, 0.55 },
        },
    },
    contrast = {
        name       = "SET_CONTRAST",
        background = { 0.00, 0.00, 0.00 },
        bgAlpha    = 1.00,
        border     = { 1.00, 1.00, 1.00, 1.00 },
        text = {
            label    = { 1.00, 1.00, 0.00 },
            value    = { 1.00, 1.00, 1.00 },
            positive = { 0.00, 1.00, 0.00 },
            negative = { 1.00, 0.20, 0.20 },
            guild    = { 0.00, 1.00, 1.00 },
            elite    = { 1.00, 0.65, 0.00 },
            rare     = { 1.00, 1.00, 1.00 },
            hint     = { 0.85, 0.85, 0.85 },
        },
    },
    pardona = {
        name       = "SET_PARDONA",
        background = { 0.03, 0.06, 0.16 },
        bgAlpha    = 0.92,
        border     = { 0.78, 0.64, 0.32, 0.90 },
        text = {
            label    = { 0.85, 0.69, 0.22 },
            value    = { 0.96, 0.94, 0.88 },
            positive = { 0.45, 0.90, 0.55 },
            negative = { 0.95, 0.40, 0.40 },
            guild    = { 0.55, 0.78, 1.00 },
            elite    = { 1.00, 0.84, 0.40 },
            rare     = { 0.80, 0.84, 0.95 },
            hint     = { 0.58, 0.62, 0.75 },
        },
    },
}

-- Border colors by unit reaction (used when "Color border" is on).
ColorSets.REACTION = {
    hostile  = { 1.00, 0.20, 0.20 },
    neutral  = { 1.00, 0.85, 0.20 },
    friendly = { 0.25, 0.90, 0.25 },
}

-- Blizzard defaults, used to undo our changes when the Blizzard set is active.
-- Read from the client when available, otherwise these values are used.
ColorSets.BLIZZARD_BACKGROUND = { 0.09, 0.09, 0.19, 1.00 }
ColorSets.BLIZZARD_BORDER     = { 1.00, 1.00, 1.00, 1.00 }

-- { r, g, b } from a Blizzard color table/ColorMixin with r, g, b fields, or nil when
-- the table or one of its fields is missing or secret.
function ColorSets.FromColorTable(c)
    local S = ns.Secret
    c = S.Table(c)
    if not c then return nil end
    local r, g, b = S.Number(S.Field(c, "r")), S.Number(S.Field(c, "g")), S.Number(S.Field(c, "b"))
    if r and g and b then return { r, g, b } end
    return nil
end

-- Display order of the set keys.
function ColorSets.Order()
    return ORDER
end

-- The set with the given key, or the default set.
function ColorSets.Get(key)
    return SETS[key] or SETS[DEFAULT_SET]
end

-- True when key names an existing set.
function ColorSets.Exists(key)
    return SETS[key] ~= nil
end

-- The set chosen in the options.
function ColorSets.Current()
    local db = ns.db
    return ColorSets.Get(db and db.colorSet)
end

-- r, g, b of a text role ("label", "value", ...) in the current set.
function ColorSets.TextColor(role)
    local set = ColorSets.Current()
    local c = set.text[role] or SETS[DEFAULT_SET].text[role] or SETS[DEFAULT_SET].text.value
    return c[1], c[2], c[3]
end

-- "|cffrrggbb" escape for r, g, b in 0..1.
function ColorSets.Escape(r, g, b)
    local floor = math.floor
    return ("|cff%02x%02x%02x"):format(floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- "|cffrrggbb" escape for a text role in the current set.
function ColorSets.TextEscape(role)
    return ColorSets.Escape(ColorSets.TextColor(role))
end

-- { r, g, b } of a text role in the current set.
function ColorSets.Role(role)
    local r, g, b = ColorSets.TextColor(role)
    return { r, g, b }
end

-- text wrapped in the color of a role. text must not be a secret value.
function ColorSets.Colorize(role, text)
    return ColorSets.TextEscape(role) .. tostring(text) .. "|r"
end
