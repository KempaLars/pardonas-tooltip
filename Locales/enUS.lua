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

-- Options: general
L.RESET               = "Reset settings"
L.RESET_BUTTON        = "Reset"
L.RESET_TT            = "Resets all settings of Pardona's ToolTips to their defaults."
