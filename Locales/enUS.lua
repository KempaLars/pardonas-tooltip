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
L.HELP_HELP         = "/ptt help – show this list"
L.RESET_DONE        = "All settings have been reset."
L.UNKNOWN_COMMAND   = "Unknown command \"%s\". Type /ptt help for a list."
L.OPEN_AFTER_COMBAT = "The options will open after combat."
L.NO_SETTINGS_API   = "The options window is not available in this client."

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
L.OPT_MANA                 = "Mana"
L.OPT_MANA_TT              = "Shows current and maximum mana if mana is the unit's main resource."
L.OPT_ITEM_LEVEL           = "Item level (players)"
L.OPT_ITEM_LEVEL_TT        = "Shows the average item level. Other players are inspected out of combat when they are in range."
L.OPT_CLASSIFICATION       = "Classification (mobs)"
L.OPT_CLASSIFICATION_TT    = "Adds Elite, Rare, Rare Elite or Boss to the level line of mobs."

-- Tooltip lines
L.LINE_TARGET       = "Target:"
L.LINE_SPEED        = "Speed:"
L.LINE_MANA         = "Mana:"
L.LINE_ITEM_LEVEL   = "Item level:"
L.TARGET_YOU        = ">> YOU <<"
L.CLASS_ELITE       = "(Elite)"
L.CLASS_RARE        = "(Rare)"
L.CLASS_RAREELITE   = "(Rare Elite)"
L.CLASS_BOSS        = "(Boss)"

-- Number formats
L.THOUSANDS_SEPARATOR = ","
L.DECIMAL_SEPARATOR   = "."
L.PERCENT_FORMAT      = "%d%%"
L.RATIO_FORMAT        = "%s / %s"
L.HEALTH_FORMAT       = "%s (%s)"

-- Options: general
L.RESET               = "Reset settings"
L.RESET_BUTTON        = "Reset"
L.RESET_TT            = "Resets all settings of Pardona's ToolTips to their defaults."
