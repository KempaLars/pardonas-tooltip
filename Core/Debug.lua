-- Pardona's ToolTips - /ptt debug: what the game lets the addon read.
--
-- Prints for "player", "mouseover", "target" and (when in a group) "party1": existence,
-- name, GUID availability, health, power and the percent APIs, each as its value or
-- "secret", plus the C_Secrets predicates about units and the available talent APIs.
--
-- Every call is protected and secret values are never compared, calculated or turned
-- into text: they are only reported as "secret". The command can never raise a Lua error.

local _, ns = ...
local L = ns.L
local S = ns.Secret
local Units = ns.Units
local Spec = ns.Spec

local Debug = {}
ns.Debug = Debug

local UNITS = { "player", "mouseover", "target", "party1" }

-- Text for one value: its plain text, "secret" or "nil".
local function Describe(v)
    if S.IsSecret(v) then return L.DEBUG_SECRET end
    if v == nil then return "nil" end
    local ok, text = pcall(tostring, v)
    return ok and text or L.DEBUG_ERROR
end

-- Calls fn(...) protected and describes its first result.
local function Result(fn, ...)
    if type(fn) ~= "function" then return L.DEBUG_MISSING end
    local ok, v = pcall(fn, ...)
    if not ok then return L.DEBUG_ERROR end
    return Describe(v)
end

local function YesNo(flag)
    return flag and L.DEBUG_YES or L.DEBUG_NO
end

local function Pairs(list)
    return table.concat(list, ", ")
end

-- Sorted function names of C_Secrets matching filter(name).
local function SecretPredicates(filter)
    local secrets = S.Table(C_Secrets)
    local names = {}
    if not secrets then return names end
    for name, fn in pairs(secrets) do
        if type(name) == "string" and type(fn) == "function" and filter(name) then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    return names
end

local function IsUnitPredicate(name)
    return name:find("Unit", 1, true) ~= nil and name:find("Aura", 1, true) == nil
end

local function IsGlobalPredicate(name)
    return name:sub(1, 3) == "Has"
end

local function PrintGlobals()
    local curves = S.Table(CurveConstants)
    ns.Print(L.DEBUG_HEADER)
    ns.Print(Pairs({
        "issecretvalue=" .. YesNo(type(_G.issecretvalue) == "function"),
        "canaccesstable=" .. YesNo(type(_G.canaccesstable) == "function"),
        "C_Secrets=" .. YesNo(S.Table(C_Secrets) ~= nil),
        "UnitHealthPercent=" .. YesNo(type(UnitHealthPercent) == "function"),
        "UnitPowerPercent=" .. YesNo(type(UnitPowerPercent) == "function"),
        "CurveConstants.ScaleTo100=" .. YesNo(curves ~= nil and curves.ScaleTo100 ~= nil),
    }))
    local secrets = S.Table(C_Secrets)
    local parts = {}
    for _, name in ipairs(SecretPredicates(IsGlobalPredicate)) do
        parts[#parts + 1] = "C_Secrets." .. name .. "=" .. Result(secrets[name])
    end
    if #parts > 0 then ns.Print(Pairs(parts)) end
    local traits = S.Table(C_Traits)
    ns.Print(Pairs({
        "GetNumTalentTabs=" .. YesNo(type(_G.GetNumTalentTabs) == "function"),
        "GetTalentTabInfo=" .. YesNo(type(_G.GetTalentTabInfo) == "function"),
        "C_Traits.GetTreeNodes=" .. YesNo(traits ~= nil and type(traits.GetTreeNodes) == "function"),
        "C_Traits.GenerateInspectImportString=" .. YesNo(traits ~= nil
            and type(traits.GenerateInspectImportString) == "function"),
        L.LINE_SPEC .. " " .. Describe(Spec.Text(false)),
    }))
end

local function GUIDState(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok then return L.DEBUG_ERROR end
    if S.IsSecret(guid) then return L.DEBUG_SECRET end
    if guid == nil then return "nil" end
    return L.DEBUG_AVAILABLE
end

local function PrintUnit(unit)
    -- A secret value must not be compared: check it first, then use the clean value.
    local exists = S.Call(UnitExists, unit)
    local secret = S.IsSecret(exists)
    local present = S.Boolean(exists) == true
    if not secret and not present then
        if unit == "party1" then return end   -- not in a group: no output
        ns.Print(("[%s] UnitExists=%s"):format(unit, Describe(exists)))
        return
    end
    ns.Print(("[%s] %s"):format(unit, Pairs({
        "UnitExists=" .. Describe(exists),
        "UnitName=" .. Result(UnitName, unit),
        "UnitGUID=" .. GUIDState(unit),
    })))
    ns.Print(Pairs({
        "UnitHealth=" .. Result(UnitHealth, unit),
        "UnitHealthMax=" .. Result(UnitHealthMax, unit),
        "UnitHealthPercent=" .. (type(UnitHealthPercent) == "function"
            and Describe(Units.HealthPercentRaw(unit)) or L.DEBUG_MISSING),
    }))

    local ok, powerType, token = pcall(UnitPowerType, unit)
    if not ok then powerType, token = nil, nil end
    local cleanType = S.Number(powerType)
    local _, _, name = Units.PowerType(unit)
    ns.Print(Pairs({
        ("UnitPowerType=%s %s (%s)"):format(Describe(powerType), Describe(token), Describe(name)),
        "UnitPower=" .. Result(UnitPower, unit, cleanType),
        "UnitPowerMax=" .. Result(UnitPowerMax, unit, cleanType),
        "UnitPowerPercent=" .. ((type(UnitPowerPercent) == "function" and cleanType)
            and Describe(Units.PowerPercentRaw(unit, cleanType)) or L.DEBUG_MISSING),
    }))

    local secrets = S.Table(C_Secrets)
    local parts = {}
    for _, predicate in ipairs(SecretPredicates(IsUnitPredicate)) do
        local value
        if predicate:find("Tokens", 1, true) then
            value = Result(secrets[predicate], unit, "player")
        else
            value = Result(secrets[predicate], unit)
        end
        parts[#parts + 1] = "C_Secrets." .. predicate .. "=" .. value
    end
    if #parts > 0 then ns.Print(Pairs(parts)) end
end

-- Prints the whole report. Errors are caught and reported in one line.
function Debug.Run()
    local ok = pcall(PrintGlobals)
    for _, unit in ipairs(UNITS) do
        ok = pcall(PrintUnit, unit) and ok
    end
    if not ok then ns.Print(L.DEBUG_FAILED) end
end
