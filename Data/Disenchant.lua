-- Pardona's ToolTips - disenchanting data (Classic item levels).
--
-- Built by hand from publicly documented facts:
--   https://warcraft.wiki.gg/wiki/Disenchanting_tables  (results, chances, quantities)
--   https://warcraft.wiki.gg/wiki/Disenchanting          (required Enchanting skill)
--   retrieved 2026-11-16. No data from other addons.
-- The wiki marks both tables as "pre Battle for Azeroth"; they use item level (iLvl).
-- Only Classic materials are included (no Burning Crusade rows).
--
-- To correct a Forever difference, edit the matching row below. Each row:
--   { min = first item level, max = last item level, results = { RESULT, ... } }
-- RESULT = { itemID, chance in percent, minimum quantity, maximum quantity }
-- Material names are not stored; they are read from the game at runtime (localized).

local _, ns = ...

-- Material item IDs
local STRANGE_DUST          = 10940
local SOUL_DUST             = 11083
local VISION_DUST           = 11137
local DREAM_DUST            = 11176
local ILLUSION_DUST         = 16204
local LESSER_MAGIC          = 10938
local GREATER_MAGIC         = 10939
local LESSER_ASTRAL         = 10998
local GREATER_ASTRAL        = 11082
local LESSER_MYSTIC         = 11134
local GREATER_MYSTIC        = 11135
local LESSER_NETHER         = 11174
local GREATER_NETHER        = 11175
local LESSER_ETERNAL        = 16202
local GREATER_ETERNAL       = 16203
local SMALL_GLIMMERING      = 10978
local LARGE_GLIMMERING      = 11084
local SMALL_GLOWING         = 11138
local LARGE_GLOWING         = 11139
local SMALL_RADIANT         = 11177
local LARGE_RADIANT         = 11178
local SMALL_BRILLIANT       = 14343
local LARGE_BRILLIANT       = 14344
local NEXUS_CRYSTAL         = 20725

ns.DisenchantData = {
    -- Uncommon (green) items: armor and weapons differ.
    uncommon = {
        armor = {
            { min = 5,  max = 15, results = { { STRANGE_DUST, 80, 1, 2 }, { LESSER_MAGIC, 20, 1, 2 } } },
            { min = 16, max = 20, results = { { STRANGE_DUST, 75, 2, 3 }, { GREATER_MAGIC, 20, 1, 2 }, { SMALL_GLIMMERING, 5, 1, 1 } } },
            { min = 21, max = 25, results = { { STRANGE_DUST, 75, 4, 6 }, { LESSER_ASTRAL, 15, 1, 2 }, { SMALL_GLIMMERING, 10, 1, 1 } } },
            { min = 26, max = 30, results = { { SOUL_DUST, 75, 1, 2 }, { GREATER_ASTRAL, 20, 1, 2 }, { LARGE_GLIMMERING, 5, 1, 1 } } },
            { min = 31, max = 35, results = { { SOUL_DUST, 75, 2, 5 }, { LESSER_MYSTIC, 20, 1, 2 }, { SMALL_GLOWING, 5, 1, 1 } } },
            { min = 36, max = 40, results = { { VISION_DUST, 75, 1, 2 }, { GREATER_MYSTIC, 20, 1, 2 }, { LARGE_GLOWING, 5, 1, 1 } } },
            { min = 41, max = 45, results = { { VISION_DUST, 75, 2, 5 }, { LESSER_NETHER, 20, 1, 2 }, { SMALL_RADIANT, 5, 1, 1 } } },
            { min = 46, max = 50, results = { { DREAM_DUST, 75, 1, 2 }, { GREATER_NETHER, 20, 1, 2 }, { LARGE_RADIANT, 5, 1, 1 } } },
            { min = 51, max = 55, results = { { DREAM_DUST, 75, 2, 5 }, { LESSER_ETERNAL, 20, 1, 2 }, { SMALL_BRILLIANT, 5, 1, 1 } } },
            { min = 56, max = 60, results = { { ILLUSION_DUST, 75, 1, 2 }, { GREATER_ETERNAL, 20, 1, 2 }, { LARGE_BRILLIANT, 5, 1, 1 } } },
            { min = 61, max = 65, results = { { ILLUSION_DUST, 75, 2, 5 }, { GREATER_ETERNAL, 20, 2, 3 }, { LARGE_BRILLIANT, 5, 1, 1 } } },
        },
        weapon = {
            { min = 6,  max = 15, results = { { STRANGE_DUST, 20, 1, 2 }, { LESSER_MAGIC, 80, 1, 2 } } },
            { min = 16, max = 20, results = { { STRANGE_DUST, 20, 2, 3 }, { GREATER_MAGIC, 75, 1, 2 }, { SMALL_GLIMMERING, 5, 1, 1 } } },
            { min = 21, max = 25, results = { { STRANGE_DUST, 15, 4, 6 }, { LESSER_ASTRAL, 75, 1, 2 }, { SMALL_GLIMMERING, 10, 1, 1 } } },
            { min = 26, max = 30, results = { { SOUL_DUST, 20, 1, 2 }, { GREATER_ASTRAL, 75, 1, 2 }, { LARGE_GLIMMERING, 5, 1, 1 } } },
            { min = 31, max = 35, results = { { SOUL_DUST, 20, 2, 5 }, { LESSER_MYSTIC, 75, 1, 2 }, { SMALL_GLOWING, 5, 1, 1 } } },
            { min = 36, max = 40, results = { { VISION_DUST, 20, 1, 2 }, { GREATER_MYSTIC, 75, 1, 2 }, { LARGE_GLOWING, 5, 1, 1 } } },
            { min = 41, max = 45, results = { { VISION_DUST, 20, 2, 5 }, { LESSER_NETHER, 75, 1, 2 }, { SMALL_RADIANT, 5, 1, 1 } } },
            { min = 46, max = 50, results = { { DREAM_DUST, 20, 1, 2 }, { GREATER_NETHER, 75, 1, 2 }, { LARGE_RADIANT, 5, 1, 1 } } },
            { min = 51, max = 55, results = { { DREAM_DUST, 22, 2, 5 }, { LESSER_ETERNAL, 75, 1, 2 }, { SMALL_BRILLIANT, 3, 1, 1 } } },
            { min = 56, max = 60, results = { { ILLUSION_DUST, 22, 1, 2 }, { GREATER_ETERNAL, 75, 1, 2 }, { LARGE_BRILLIANT, 3, 1, 1 } } },
            { min = 61, max = 65, results = { { ILLUSION_DUST, 22, 2, 5 }, { GREATER_ETERNAL, 75, 2, 3 }, { LARGE_BRILLIANT, 3, 1, 1 } } },
        },
    },

    -- Rare (blue) items: same for armor and weapons, always one shard.
    rare = {
        { min = 1,  max = 25, results = { { SMALL_GLIMMERING, 100, 1, 1 } } },
        { min = 26, max = 30, results = { { LARGE_GLIMMERING, 100, 1, 1 } } },
        { min = 31, max = 35, results = { { SMALL_GLOWING, 100, 1, 1 } } },
        { min = 36, max = 40, results = { { LARGE_GLOWING, 100, 1, 1 } } },
        { min = 41, max = 45, results = { { SMALL_RADIANT, 100, 1, 1 } } },
        { min = 46, max = 50, results = { { LARGE_RADIANT, 100, 1, 1 } } },
        { min = 51, max = 55, results = { { SMALL_BRILLIANT, 100, 1, 1 } } },
        { min = 56, max = 65, results = { { LARGE_BRILLIANT, 99.5, 1, 1 }, { NEXUS_CRYSTAL, 0.5, 1, 1 } } },
    },

    -- Epic (purple) items: same for armor and weapons.
    -- The wiki row "61-88" is extended to 100 so Classic raid epics (up to item level 92)
    -- are covered; Burning Crusade materials do not exist on Forever.
    epic = {
        { min = 40, max = 45,  results = { { SMALL_RADIANT, 100, 2, 4 } } },
        { min = 46, max = 50,  results = { { LARGE_RADIANT, 100, 2, 4 } } },
        { min = 51, max = 55,  results = { { SMALL_BRILLIANT, 100, 2, 4 } } },
        { min = 56, max = 60,  results = { { NEXUS_CRYSTAL, 100, 1, 1 } } },
        { min = 61, max = 100, results = { { NEXUS_CRYSTAL, 100, 1, 2 } } },
    },

    -- Required Enchanting skill: { min item level, max item level, skill }.
    -- Epic items below item level 61 use the rare ranges (wiki note).
    skill = {
        uncommon = {
            { 1, 20, 1 }, { 21, 25, 25 }, { 26, 30, 50 }, { 31, 35, 75 }, { 36, 40, 100 },
            { 41, 45, 125 }, { 46, 50, 150 }, { 51, 55, 175 }, { 56, 60, 200 }, { 61, 99, 225 },
        },
        rare = {
            { 1, 25, 25 }, { 26, 30, 50 }, { 31, 35, 75 }, { 36, 40, 100 }, { 41, 45, 125 },
            { 46, 50, 150 }, { 51, 55, 175 }, { 56, 60, 200 }, { 61, 97, 225 },
        },
        epic = {
            { 61, 100, 225 },
        },
    },
}
