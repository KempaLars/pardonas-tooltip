-- Pardona's ToolTips - tooltip fonts.
--
-- Offers the standard WoW fonts and, when another addon provides it at runtime,
-- the fonts registered with LibSharedMedia-3.0 (never embedded here).
-- Fonts are applied to the shared tooltip font objects, which GameTooltip and the
-- comparison tooltips use.

local _, ns = ...
local L = ns.L

local Fonts = {}
ns.Fonts = Fonts

local LSM_PREFIX = "lsm:"
local DEFAULT_FONT = "builtin:friz"

local BUILTIN = {
    { key = "builtin:friz",     label = "FONT_FRIZ",     path = "Fonts\\FRIZQT__.TTF" },
    { key = "builtin:arialn",   label = "FONT_ARIALN",   path = "Fonts\\ARIALN.TTF" },
    { key = "builtin:skurri",   label = "FONT_SKURRI",   path = "Fonts\\SKURRI.TTF" },
    { key = "builtin:morpheus", label = "FONT_MORPHEUS", path = "Fonts\\MORPHEUS.TTF" },
}

local builtinByKey = {}
for _, font in ipairs(BUILTIN) do builtinByKey[font.key] = font end

-- Font objects and their original flags, captured before the first change.
local FONT_OBJECTS = { "GameTooltipHeaderText", "GameTooltipText", "GameTooltipTextSmall" }
local originalFlags = {}

---------------------------------------------------------------------------
-- LibSharedMedia (optional, detected at runtime)
---------------------------------------------------------------------------
local function GetLSM()
    -- LibStub is not part of the game client; it only exists when another addon ships it.
    -- Read through _G on purpose so a missing LibStub is a normal case, not an undefined global.
    local libStub = _G.LibStub
    if type(libStub) ~= "table" or type(libStub.GetLibrary) ~= "function" then return nil end
    local ok, lsm = pcall(libStub.GetLibrary, libStub, "LibSharedMedia-3.0", true)
    if ok and type(lsm) == "table" then return lsm end
    return nil
end

local function LSMFontNames(lsm)
    local ok, names = pcall(lsm.List, lsm, "font")
    if ok and type(names) == "table" then return names end
    return {}
end

local function LSMFontPath(lsm, name)
    local ok, path = pcall(lsm.Fetch, lsm, "font", name, true)
    if ok and type(path) == "string" and path ~= "" then return path end
    return nil
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Dropdown entries: { { value = key, label = text }, ... }. Built-in fonts first,
-- then LibSharedMedia fonts that do not point to a built-in font file.
function Fonts.List()
    local list = {}
    local seenPaths = {}
    for _, font in ipairs(BUILTIN) do
        list[#list + 1] = { value = font.key, label = L[font.label] }
        seenPaths[font.path:lower()] = true
    end
    local lsm = GetLSM()
    if lsm then
        for _, name in ipairs(LSMFontNames(lsm)) do
            local path = LSMFontPath(lsm, name)
            if path and not seenPaths[path:lower()] then
                seenPaths[path:lower()] = true
                list[#list + 1] = { value = LSM_PREFIX .. name, label = name }
            end
        end
    end
    return list
end

-- File path for a stored font key. Unknown or unavailable fonts fall back to Friz Quadrata.
function Fonts.Resolve(key)
    local font = builtinByKey[key]
    if font then return font.path end
    if type(key) == "string" and key:sub(1, #LSM_PREFIX) == LSM_PREFIX then
        local lsm = GetLSM()
        local path = lsm and LSMFontPath(lsm, key:sub(#LSM_PREFIX + 1))
        if path then return path end
    end
    return builtinByKey[DEFAULT_FONT].path
end

local function SetFontObject(name, object, path, size)
    if type(object) ~= "table" or type(object.SetFont) ~= "function" then return end
    if originalFlags[name] == nil then
        local ok, _, _, flags = pcall(object.GetFont, object)
        originalFlags[name] = (ok and type(flags) == "string") and flags or ""
    end
    local ok, applied = pcall(object.SetFont, object, path, size, originalFlags[name])
    -- SetFont returns false when the file cannot be loaded: fall back to the default font.
    if not ok or applied == false then
        pcall(object.SetFont, object, builtinByKey[DEFAULT_FONT].path, size, originalFlags[name])
    end
end

-- Applies font and sizes from the settings to the tooltip font objects.
function Fonts.Apply()
    local db = ns.db
    if not db then return end
    local path = Fonts.Resolve(db.font)
    local textSize = db.fontSizeText
    SetFontObject("GameTooltipHeaderText", GameTooltipHeaderText, path, db.fontSizeHeader)
    SetFontObject("GameTooltipText", GameTooltipText, path, textSize)
    SetFontObject("GameTooltipTextSmall", GameTooltipTextSmall, path, math.max(6, textSize - 2))
end

-- Font object names, for modules that need them.
function Fonts.Objects()
    return FONT_OBJECTS
end

---------------------------------------------------------------------------
-- Re-apply when LibSharedMedia registers fonts after us (load order of other addons).
---------------------------------------------------------------------------
local lsmHooked = false

local function HookLSM()
    if lsmHooked then return end
    local lsm = GetLSM()
    if not lsm or type(lsm.RegisterCallback) ~= "function" then return end
    lsmHooked = true
    pcall(lsm.RegisterCallback, Fonts, "LibSharedMedia_Registered", function(_, mediaType)
        local db = ns.db
        if mediaType == "font" and db and type(db.font) == "string"
            and db.font:sub(1, #LSM_PREFIX) == LSM_PREFIX then
            Fonts.Apply()
        end
    end)
end

ns.OnLogin(function()
    HookLSM()
    Fonts.Apply()
end)
