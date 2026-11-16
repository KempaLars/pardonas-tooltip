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

-- WoW API, Blizzard frames, constants and mixins the addon reads.
-- Deliberately read through _G and therefore not listed: issecretvalue and
-- canaccesstable (only on clients with secret values), LibStub (only present when
-- another addon ships it) and InspectFrame (load-on-demand Blizzard UI).
read_globals = {
    -- Frames and font objects
    "GameTooltip",
    "GameTooltipHeaderText",
    "GameTooltipStatusBar",
    "GameTooltipText",
    "GameTooltipTextSmall",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "UIParent",

    -- Namespaces and enums
    "C_ClassColor",
    "C_Item",
    "C_Timer",
    "Enum",
    "TooltipDataProcessor",

    -- Constants, global strings and color tables
    "ITEM_QUALITY_COLORS",
    "RAID_CLASS_COLORS",
    "TOOLTIP_DEFAULT_BACKGROUND_COLOR",
    "TOOLTIP_DEFAULT_COLOR",
    "TOOLTIP_UNIT_LEVEL",

    -- Functions: frames, hooks and errors
    "CreateFrame",
    "geterrorhandler",
    "hooksecurefunc",

    -- Functions: game state
    "GetLocale",
    "GetTime",
    "InCombatLockdown",
    "IsLoggedIn",

    -- Functions: inspect and equipment
    "CanInspect",
    "CheckInteractDistance",
    "ClearInspectPlayer",
    "GetInventoryItemID",
    "GetInventoryItemLink",
    "NotifyInspect",

    -- Functions: tooltip (hook targets)
    "GameTooltip_SetDefaultAnchor",
    "SharedTooltip_SetBackdropStyle",

    -- Functions: units
    "GetGuildInfo",
    "GetUnitSpeed",
    "UnitClass",
    "UnitClassification",
    "UnitExists",
    "UnitGUID",
    "UnitHealth",
    "UnitHealthMax",
    "UnitIsPlayer",
    "UnitIsUnit",
    "UnitName",
    "UnitPower",
    "UnitPowerMax",
    "UnitPowerType",
    "UnitReaction",

    -- Settings API (options window)
    "CreateSettingsButtonInitializer",
    "CreateSettingsListSectionHeaderInitializer",
    "MinimalSliderWithSteppersMixin",
    "Settings",

    -- Utility functions
    "wipe",
}
