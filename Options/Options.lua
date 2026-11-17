-- Pardona's ToolTips - options window (Blizzard Settings API, vertical layout).
-- Every control is bound to PardonasToolTipsDB through Settings.RegisterAddOnSetting
-- and applies its change immediately, without /reload.
-- With lib-pardona the page is a subcategory of "Pardona's Addons"; without it the page
-- is registered as an AddOn category of its own, as before.

local _, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local VARIABLE_PREFIX = "PardonasToolTips_"

local category, layout
local viaLibrary = false -- category is a lib-pardona subcategory
local settings = {} -- db key -> setting object

---------------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------------
local function OnSettingChanged()
    ns.Appearance.Refresh()
    ns.HealthText.Update()
end

local function RegisterSetting(key, name)
    local default = ns.DEFAULTS[key]
    local setting = Settings.RegisterAddOnSetting(category, VARIABLE_PREFIX .. key, key, ns.db,
        type(default), name, default)
    setting:SetValueChangedCallback(OnSettingChanged)
    settings[key] = setting
    return setting
end

local function AddHeader(text)
    if type(CreateSettingsListSectionHeaderInitializer) == "function" then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
end

-- entries: function returning { { value = ..., label = ... }, ... } (evaluated when opened).
local function AddDropdown(key, name, tooltip, entries)
    local setting = RegisterSetting(key, name)
    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        for _, entry in ipairs(entries()) do
            container:Add(entry.value, entry.label)
        end
        return container:GetData()
    end
    return Settings.CreateDropdown(category, setting, GetOptions, tooltip)
end

local function AddSlider(key, name, tooltip, formatter)
    local setting = RegisterSetting(key, name)
    local limits = ns.LIMITS[key]
    local sliderOptions = Settings.CreateSliderOptions(limits[1], limits[2], limits[3])
    local labels = MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label
    if labels and labels.Right then
        sliderOptions:SetLabelFormatter(labels.Right, formatter)
    end
    return Settings.CreateSlider(category, setting, sliderOptions, tooltip)
end

local function AddCheckbox(key, name, tooltip)
    local setting = RegisterSetting(key, name)
    return Settings.CreateCheckbox(category, setting, tooltip)
end

local function AddButton(name, buttonText, onClick, tooltip)
    if type(CreateSettingsButtonInitializer) ~= "function" then return end
    layout:AddInitializer(CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, true))
end

-- "Show minimap button": a proxy setting on the shared lib-pardona state, not stored in
-- our own settings. Only added when the library is loaded.
local function AddMinimapCheckbox()
    local LP = ns.Pardona.Lib()
    if not LP or type(Settings.RegisterProxySetting) ~= "function" then return end
    local function GetValue()
        return not LP:IsMinimapHidden()
    end
    local function SetValue(value)
        LP:SetMinimapHidden(not value)
    end
    local ok, setting = pcall(Settings.RegisterProxySetting, category,
        VARIABLE_PREFIX .. "minimapButton", type(true), L.OPT_MINIMAP, true, GetValue, SetValue)
    if not ok or not setting then return end
    Settings.CreateCheckbox(category, setting, L.OPT_MINIMAP_TT)
end

-- Shows child only while predicate() is true (where the client supports it).
local function DependsOn(child, parent, predicate)
    if child and parent and type(child.SetParentInitializer) == "function" then
        child:SetParentInitializer(parent, predicate)
    end
end

---------------------------------------------------------------------------
-- Dropdown entries
---------------------------------------------------------------------------
local POSITION_LABELS = {
    cursor      = "POS_CURSOR",
    topleft     = "POS_TOPLEFT",
    topright    = "POS_TOPRIGHT",
    bottomleft  = "POS_BOTTOMLEFT",
    bottomright = "POS_BOTTOMRIGHT",
    center      = "POS_CENTER",
    blizzard    = "POS_BLIZZARD",
}

local function PositionEntries()
    local list = {}
    for _, key in ipairs(ns.Appearance.POSITIONS) do
        list[#list + 1] = { value = key, label = L[POSITION_LABELS[key]] }
    end
    return list
end

local function ColorSetEntries()
    local list = {}
    for _, key in ipairs(ns.ColorSets.Order()) do
        list[#list + 1] = { value = key, label = L[ns.ColorSets.Get(key).name] }
    end
    return list
end

local function CompareEntries()
    return {
        { value = "always", label = L.COMPARE_ALWAYS },
        { value = "shift",  label = L.COMPARE_SHIFT },
        { value = "off",    label = L.COMPARE_OFF },
    }
end

local function FontEntries()
    return ns.Fonts.List()
end

local function FormatPercent(value)
    return ("%d %%"):format(value)
end

local function FormatPixels(value)
    return ("%d px"):format(value)
end

local function FormatPoints(value)
    return ("%d"):format(value)
end

local function FormatTwoDecimals(value)
    return ns.Format.Decimal(value, 2)
end

local function FormatOneDecimal(value)
    return ns.Format.Decimal(value, 1)
end

---------------------------------------------------------------------------
-- Reset
---------------------------------------------------------------------------

-- Resets all settings. Bound controls are updated through their setting objects so an
-- open options window shows the new values at once.
function Options.ResetAll()
    for key, setting in pairs(settings) do
        pcall(setting.SetValue, setting, ns.DEFAULTS[key])
    end
    ns.Database.Reset()
    ns.Appearance.Refresh()
    ns.Print(L.RESET_DONE)
end

---------------------------------------------------------------------------
-- Category
---------------------------------------------------------------------------
local function Build()
    local LP = ns.Pardona.Lib()
    if LP then
        category, layout = LP:RegisterSettingsVertical(ns.Pardona.ID, L.SETTINGS_NAME)
        viaLibrary = category ~= nil
    end
    if not category then
        category, layout = Settings.RegisterVerticalLayoutCategory(L.TITLE)
    end

    AddHeader(L.SECTION_APPEARANCE)

    local positionInit = AddDropdown("position", L.POSITION, L.POSITION_TT, PositionEntries)
    local offsetInit = AddSlider("offset", L.OFFSET, L.OFFSET_TT, FormatPixels)
    DependsOn(offsetInit, positionInit, function()
        return ns.db ~= nil and ns.Appearance.IsCorner(ns.db.position)
    end)

    AddSlider("scale", L.SCALE, L.SCALE_TT, FormatPercent)
    AddDropdown("font", L.FONT, L.FONT_TT, FontEntries)
    AddSlider("fontSizeHeader", L.FONT_SIZE_HEADER, L.FONT_SIZE_HEADER_TT, FormatPoints)
    AddSlider("fontSizeText", L.FONT_SIZE_TEXT, L.FONT_SIZE_TEXT_TT, FormatPoints)
    AddDropdown("colorSet", L.COLOR_SET, L.COLOR_SET_TT, ColorSetEntries)
    AddCheckbox("colorBorder", L.COLOR_BORDER, L.COLOR_BORDER_TT)

    AddHeader(L.SECTION_UNITS)
    AddCheckbox("unitNameClassColor", L.OPT_NAME_CLASS_COLOR, L.OPT_NAME_CLASS_COLOR_TT)
    AddCheckbox("unitGuildColor", L.OPT_GUILD_COLOR, L.OPT_GUILD_COLOR_TT)
    AddCheckbox("unitClassLineColor", L.OPT_CLASS_LINE_COLOR, L.OPT_CLASS_LINE_COLOR_TT)
    AddCheckbox("unitHealthText", L.OPT_HEALTH_TEXT, L.OPT_HEALTH_TEXT_TT)
    AddCheckbox("unitTarget", L.OPT_TARGET, L.OPT_TARGET_TT)
    AddCheckbox("unitSpeed", L.OPT_SPEED, L.OPT_SPEED_TT)
    AddCheckbox("unitMana", L.OPT_RESOURCE, L.OPT_RESOURCE_TT)
    AddCheckbox("unitItemLevel", L.OPT_ITEM_LEVEL, L.OPT_ITEM_LEVEL_TT)
    AddCheckbox("unitSpec", L.OPT_SPEC, L.OPT_SPEC_TT)
    AddCheckbox("unitClassification", L.OPT_CLASSIFICATION, L.OPT_CLASSIFICATION_TT)

    AddHeader(L.SECTION_ITEMS)
    AddCheckbox("itemLevel", L.OPT_ITEM_LEVEL_ITEMS, L.OPT_ITEM_LEVEL_ITEMS_TT)
    AddDropdown("itemCompare", L.OPT_COMPARE, L.OPT_COMPARE_TT, CompareEntries)
    AddCheckbox("itemHideAppearance", L.OPT_HIDE_APPEARANCE, L.OPT_HIDE_APPEARANCE_TT)

    AddHeader(L.SECTION_PRICES)
    -- TradeSkillMaster is an optional dependency and therefore loaded before us.
    if not ns.Prices.Available() then AddHeader(L.TSM_MISSING) end
    AddCheckbox("deChances", L.OPT_DE_CHANCES, L.OPT_DE_CHANCES_TT)
    AddCheckbox("deValue", L.OPT_DE_VALUE, L.OPT_DE_VALUE_TT)
    AddCheckbox("deRecommend", L.OPT_RECOMMEND, L.OPT_RECOMMEND_TT)
    AddSlider("ahFee", L.OPT_AH_FEE, L.OPT_AH_FEE_TT, FormatPercent)
    AddSlider("minSaleRate", L.OPT_MIN_SALE_RATE, L.OPT_MIN_SALE_RATE_TT, FormatTwoDecimals)
    AddSlider("minSoldPerDay", L.OPT_MIN_SOLD, L.OPT_MIN_SOLD_TT, FormatOneDecimal)

    AddHeader(L.SECTION_GENERAL)
    AddMinimapCheckbox()
    AddButton(L.RESET, L.RESET_BUTTON, Options.ResetAll, L.RESET_TT)

    -- A lib-pardona subcategory is already part of "Pardona's Addons".
    if not viaLibrary then Settings.RegisterAddOnCategory(category) end
end

local function SettingsAvailable()
    return type(Settings) == "table"
        and type(Settings.RegisterVerticalLayoutCategory) == "function"
        and type(Settings.RegisterAddOnSetting) == "function"
end

-- Opens the options window. In combat the window opens once combat ends.
function Options.Open()
    if not category then
        ns.Print(L.NO_SETTINGS_API)
        return
    end
    local opened = ns.RunOutOfCombat("openOptions", function()
        local LP = ns.Pardona.Lib()
        if viaLibrary and LP then
            LP:OpenSettings(ns.Pardona.ID)
        else
            Settings.OpenToCategory(category:GetID())
        end
    end)
    if not opened then ns.Print(L.OPEN_AFTER_COMBAT) end
end

ns.OnLoad(function()
    if not SettingsAvailable() then return end
    local ok, err = pcall(Build)
    if not ok then
        category = nil
        viaLibrary = false
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(err) end
    end
end)
