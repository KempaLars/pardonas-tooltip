-- Pardona's ToolTips - English (default) strings.
-- Every visible text goes through this table. Other locales only override keys.

local _, ns = ...

local L = setmetatable({}, {
    -- A missing key shows the key itself instead of raising an error.
    __index = function(_, key) return key end,
})
ns.L = L

L.TITLE = "Pardona's ToolTips"

-- Slash commands and chat output
L.HELP_HEADER       = "Commands:"
L.HELP_OPEN         = "/ptt – open the options"
L.HELP_RESET        = "/ptt reset – reset all settings to their defaults"
L.HELP_DEBUG        = "/ptt debug – show what the game lets the addon read (troubleshooting)"
L.HELP_MINIMAP      = "/ptt minimap – show or hide the shared Pardona minimap button"
L.HELP_HELP         = "/ptt help – show this list"

-- /ptt debug
L.DEBUG_HEADER      = "Diagnostics (value, \"secret\" or \"nil\"):"
L.DEBUG_SECRET      = "secret"
L.DEBUG_AVAILABLE   = "available"
L.DEBUG_MISSING     = "missing"
L.DEBUG_ERROR       = "error"
L.DEBUG_YES         = "yes"
L.DEBUG_NO          = "no"
L.DEBUG_FAILED      = "Part of the diagnostics could not be read."
L.DEBUG_SKIPPED_EVENTS = "Skipped events: %s"
L.DEBUG_NONE        = "none"
L.DEBUG_UNKNOWN     = "unknown"
L.DEBUG_SAME_AS_TARGET = "same unit as target"
L.DEBUG_TALENT_TAB  = "GetTalentTabInfo(%d, false): %s"
L.DEBUG_NODES       = "nodes"
L.DEBUG_NODES_RANKED = "nodes with rank > 0"
L.DEBUG_TOOLTIP_LINES = "GameTooltip, %d lines (left side):"
L.DEBUG_TOOLTIP_HIDDEN = "GameTooltip is not shown."
L.RESET_DONE        = "All settings have been reset."
L.UNKNOWN_COMMAND   = "Unknown command \"%s\". Type /ptt help for a list."
L.OPEN_AFTER_COMBAT = "The options will open after combat."
L.NO_SETTINGS_API   = "The options window is not available in this client."
L.LIB_NOT_LOADED    = "Shared library not loaded."

-- Shared Pardona library (lib-pardona): settings page name and status
L.SETTINGS_NAME     = "ToolTips"
L.STATUS_ACTIVE     = "active"
L.STATUS_ACTIVE_NO_TSM = "active (no TSM)"

-- Options: sections
L.SECTION_APPEARANCE = "Appearance"
L.SECTION_GENERAL    = "General"

-- Options: position
L.POSITION            = "Position"
L.POSITION_TT         = "Where tooltips with the default anchor appear (for example units in the world). Tooltips of bag slots and buttons keep their place."
L.POS_CURSOR          = "Mouse cursor"
L.POS_TOPLEFT         = "Top left"
L.POS_TOPRIGHT        = "Top right"
L.POS_BOTTOMLEFT      = "Bottom left"
L.POS_BOTTOMRIGHT     = "Bottom right"
L.POS_CENTER          = "Screen center"
L.POS_BLIZZARD        = "Blizzard default"
L.OFFSET              = "Edge distance"
L.OFFSET_TT           = "Distance in pixels from the screen edge. Only used for the corner positions."

-- Options: scale and fonts
L.SCALE               = "Scale"
L.SCALE_TT            = "Size of the tooltip and the comparison tooltips."
L.FONT                = "Font"
L.FONT_TT             = "Font for tooltip text. Fonts from LibSharedMedia are listed too if another addon provides it."
L.FONT_FRIZ           = "Friz Quadrata"
L.FONT_ARIALN         = "Arial Narrow"
L.FONT_SKURRI         = "Skurri"
L.FONT_MORPHEUS       = "Morpheus"
L.FONT_SIZE_HEADER    = "Font size: header"
L.FONT_SIZE_HEADER_TT = "Font size of the first tooltip line (name of the unit or item)."
L.FONT_SIZE_TEXT      = "Font size: text"
L.FONT_SIZE_TEXT_TT   = "Font size of the other tooltip lines. Small lines are drawn two points smaller."

-- Options: colors
L.COLOR_SET           = "Color set"
L.COLOR_SET_TT        = "Background, border and text colors of the tooltip."
L.SET_BLIZZARD        = "Blizzard"
L.SET_DARK            = "Dark"
L.SET_CONTRAST        = "High contrast"
L.SET_PARDONA         = "Pardona"
L.COLOR_BORDER        = "Color border"
L.COLOR_BORDER_TT     = "Colors the border: items by quality, players by class, NPCs by reaction (hostile, neutral, friendly)."

-- Options: players & mobs
L.SECTION_UNITS            = "Players & Mobs"
L.OPT_NAME_CLASS_COLOR     = "Name in class color"
L.OPT_NAME_CLASS_COLOR_TT  = "Shows the name of players in their class color."
L.OPT_GUILD_COLOR          = "Guild color"
L.OPT_GUILD_COLOR_TT       = "Shows the guild line of players in the guild color of the color set."
L.OPT_CLASS_LINE_COLOR     = "Color class line"
L.OPT_CLASS_LINE_COLOR_TT  = "Shows the class name of players (for example \"Mage\") in its class color."
L.OPT_HEALTH_TEXT          = "Health text"
L.OPT_HEALTH_TEXT_TT       = "Shows current and maximum health with percentage on the health bar below the tooltip."
L.OPT_TARGET               = "Target"
L.OPT_TARGET_TT            = "Shows the target of the unit. If it targets you, \">> YOU <<\" is shown."
L.OPT_SPEED                = "Speed"
L.OPT_SPEED_TT             = "Shows the current movement speed in percent of normal run speed, updated live."
L.OPT_RESOURCE             = "Resource (mana, rage, energy …)"
L.OPT_RESOURCE_TT          = "Shows a bar for the unit's main resource below the health bar, in the resource's color, with current and maximum value and percentage. If the game hides the exact values, only the percentage is shown."
L.OPT_ITEM_LEVEL           = "Item level (players)"
L.OPT_ITEM_LEVEL_TT        = "Shows the average item level. Other players are inspected out of combat when they are in range."
L.OPT_SPEC                 = "Spec (players)"
L.OPT_SPEC_TT              = "Shows the talent tree with the most points and the points of all trees, for example \"Arms (31/20/0)\". Other players are inspected together with the item level. On WoW Forever your own spec is estimated from the talent layout (experimental)."
L.OPT_CLASSIFICATION       = "Classification (mobs)"
L.OPT_CLASSIFICATION_TT    = "Adds Elite, Rare, Rare Elite or Boss to the level line of mobs."

-- Options: items
L.SECTION_ITEMS            = "Items"
L.OPT_ITEM_LEVEL_ITEMS     = "Item level on items"
L.OPT_ITEM_LEVEL_ITEMS_TT  = "Shows the item level of equipment in the title line of the tooltip."
L.OPT_COMPARE              = "Show comparison"
L.OPT_COMPARE_TT           = "Compares equipment you can wear with what you have equipped, below the tooltip. Blizzard's own Shift comparison stays unchanged."
L.COMPARE_ALWAYS           = "Always"
L.COMPARE_SHIFT            = "Only with Shift"
L.COMPARE_OFF              = "Off"
L.OPT_HIDE_APPEARANCE      = "Hide appearance collection hint"
L.OPT_HIDE_APPEARANCE_TT   = "Hides the line \"You haven't collected this appearance\" in item tooltips."

-- Options: prices & disenchanting
L.SECTION_PRICES           = "Prices & Disenchanting"
L.TSM_MISSING              = "TradeSkillMaster not found – prices and recommendation are disabled."
L.OPT_DE_CHANCES           = "Show disenchant chances"
L.OPT_DE_CHANCES_TT        = "Shows which materials an item can disenchant into, with chances and quantities."
L.OPT_DE_VALUE             = "Show disenchant value"
L.OPT_DE_VALUE_TT          = "Shows TradeSkillMaster's disenchant value (price source Destroy)."
L.OPT_RECOMMEND            = "Show recommendation"
L.OPT_RECOMMEND_TT         = "Recommends vendor, auction house or disenchanting, whichever earns the most."
L.OPT_AH_FEE               = "Auction house fee"
L.OPT_AH_FEE_TT            = "Subtracted from auction house and disenchant values in the recommendation."
L.OPT_MIN_SALE_RATE        = "Slow seller: minimum sale rate"
L.OPT_MIN_SALE_RATE_TT     = "Below this region sale rate (TSM DBRegionSaleRate) the auction house value is ignored."
L.OPT_MIN_SOLD             = "Slow seller: minimum sold per day"
L.OPT_MIN_SOLD_TT          = "Below this number of region sales per day (TSM DBRegionSoldPerDay) the auction house value is ignored."

-- Tooltip lines
L.LINE_TARGET       = "Target:"
L.LINE_SPEED        = "Speed:"
L.LINE_ITEM_LEVEL   = "Item level:"
L.LINE_SPEC         = "Spec:"
L.SPEC_FORMAT       = "%s (%s)"
L.TARGET_YOU        = ">> YOU <<"
L.CLASS_ELITE       = "(Elite)"
L.CLASS_RARE        = "(Rare)"
L.CLASS_RAREELITE   = "(Rare Elite)"
L.CLASS_BOSS        = "(Boss)"
L.ITEM_LEVEL_SHORT  = "iLvl %s"
L.INSTEAD_OF        = "Instead of %s:"
L.EMPTY_SLOT        = "(empty slot)"
L.COMPARE_NO_CHANGE = "no change"
L.SLOT_RING         = "Ring %d"
L.SLOT_TRINKET      = "Trinket %d"
L.LINE_DISENCHANT       = "Disenchant:"
L.LINE_DISENCHANT_VALUE = "Disenchant value:"
L.LINE_RECOMMENDATION   = "Recommendation:"
L.RECOMMEND_VENDOR      = "Vendor"
L.RECOMMEND_AUCTION     = "Auction house"
L.RECOMMEND_DISENCHANT  = "Disenchant"
L.RECOMMEND_FORMAT      = "%s (≈ %s)"
L.SLOW_SELLER           = "(AH: slow seller)"
L.SKILL_NEEDED          = "(Enchanting %d required)"
L.ITEM_LOADING          = "(loading)"

-- Number formats
L.THOUSANDS_SEPARATOR = ","
L.DECIMAL_SEPARATOR   = "."
L.PERCENT_FORMAT      = "%d%%"
L.PERCENT_DECIMAL_FORMAT = "%s%%"
L.PERCENT_SECRET_FORMAT = "%.0f%%"
L.RATIO_FORMAT        = "%s / %s"
L.VALUE_FORMAT        = "%s (%s)"

-- Options: general
L.RESET               = "Reset settings"
L.RESET_BUTTON        = "Reset"
L.RESET_TT            = "Resets all settings of Pardona's ToolTips to their defaults."
L.OPT_MINIMAP           = "Show minimap button"
L.OPT_MINIMAP_TT        = "Shows the shared minimap button of Pardona's Addons. The setting applies to all Pardona addons."
