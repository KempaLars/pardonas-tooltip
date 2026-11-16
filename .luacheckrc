-- luacheck configuration for Pardona's ToolTips (WoW Forever, Lua 5.1)
std = "lua51"
max_line_length = false
-- WoW callbacks receive parameters (self, event, ...) that are often unused
unused_args = false
exclude_files = { ".release" }

-- Globals the addon writes
globals = {
    "PardonasToolTipsDB",
    "SLASH_PARDONASTOOLTIPS1",
    "SLASH_PARDONASTOOLTIPS2",
    "SlashCmdList",
}

-- WoW API functions and objects the addon reads
read_globals = {
    -- namespaces and mixins
    "Enum",
    "MinimalSliderWithSteppersMixin",
    "Settings",
    "TooltipDataProcessor",
    -- frames
    "GameTooltip",
    "UIParent",
    -- functions
    "CreateFrame",
    "CreateSettingsButtonInitializer",
    "CreateSettingsListSectionHeaderInitializer",
    "GetLocale",
    "geterrorhandler",
    "hooksecurefunc",
    "InCombatLockdown",
    "IsLoggedIn",
    "wipe",
}
