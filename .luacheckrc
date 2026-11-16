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
-- another addon ships it), InspectFrame (load-on-demand Blizzard UI), TSM_API (optional
-- TradeSkillMaster), GetNumSkillLines/GetSkillLineInfo (older skill API fallback),
-- GetNumTalentTabs/GetTalentTabInfo (Classic talent tab API, may be missing on WoW
-- Forever), the power type names (global strings such as MANA, looked up by token) and
-- the classification words RARE, ELITE and BOSS (global strings, RARE may be missing).
read_globals = {
    -- Frames and font objects
    "GameTooltip",
    "GameTooltipHeaderText",
    "GameTooltipStatusBar",
    "GameTooltipText",
    "GameTooltipTextSmall",
    "ItemRefTooltip",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "UIParent",

    -- Namespaces and enums
    "C_ClassColor",
    "C_EventUtils",
    "C_Item",
    "C_Secrets",
    "C_SkillInfo",
    "C_Spell",
    "C_Timer",
    "C_TooltipComparison",
    "C_TooltipInfo",
    "C_Traits",
    "CurveConstants",
    "Enum",
    "ItemLocation",
    "TooltipDataProcessor",

    -- Constants, global strings and color tables
    "INVTYPE_WEAPONMAINHAND",
    "INVTYPE_WEAPONOFFHAND",
    "ITEM_QUALITY_COLORS",
    "RAID_CLASS_COLORS",
    "TOOLTIP_DEFAULT_BACKGROUND_COLOR",
    "TOOLTIP_DEFAULT_COLOR",
    "TOOLTIP_UNIT_LEVEL",
    "TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN",

    -- Functions: frames, hooks and errors
    "CreateFrame",
    "geterrorhandler",
    "hooksecurefunc",

    -- Functions: game state
    "GetLocale",
    "GetTime",
    "InCombatLockdown",
    "IsLoggedIn",
    "IsShiftKeyDown",

    -- Functions: inspect and equipment
    "CanDualWield",
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
    "UnitHealthPercent",
    "UnitIsPlayer",
    "UnitIsUnit",
    "UnitName",
    "UnitPower",
    "UnitPowerMax",
    "UnitPowerPercent",
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
