-- luacheck configuration for Pardona's ToolTips (WoW Forever, Lua 5.1)
-- Run from the repository root: luacheck .
std = "lua51"
max_line_length = false

-- Only the addon's own Lua files are checked.
exclude_files = {
    ".release/**",
    ".github/**",
    "media/**",
}

-- Globals the addon writes
globals = {
    -- SavedVariables
    "PardonasToolTipsDB",
    -- Slash commands
    "SLASH_PARDONASTOOLTIPS1",
    "SLASH_PARDONASTOOLTIPS2",
    SlashCmdList = {
        fields = {
            PARDONASTOOLTIPS = { read_only = false },
        },
    },
}

-- WoW API, Blizzard frames and mixins the addon reads directly.
-- Optional APIs that may be missing on this client are read through _G on purpose
-- (for example _G.issecretvalue, _G.TooltipDataProcessor, _G.C_Item) and do not
-- appear here; luacheck does not check those names.
read_globals = {
    -- Frames
    "UIParent",

    -- Functions: frames, hooks and errors
    "CreateFrame",
    "geterrorhandler",
    "hooksecurefunc",

    -- Functions: game state
    "GetLocale",
    "InCombatLockdown",
    "IsLoggedIn",

    -- Settings API (options window)
    "CreateSettingsButtonInitializer",
    "CreateSettingsListSectionHeaderInitializer",
    "MinimalSliderWithSteppersMixin",
    "Settings",

    -- Utility functions
    "wipe",
}
