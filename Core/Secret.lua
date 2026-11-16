-- Pardona's ToolTips - helpers for secret values and protected calls.
--
-- On the Midnight-based client any value returned by unit or tooltip APIs can be a
-- "secret value". Secret values must not be compared, used in arithmetic or
-- concatenated by addon code. Every module reads such values only through these
-- helpers and silently skips its output when a value is secret.

local _, ns = ...

local S = {}
ns.Secret = S

-- Resolved once; both functions are missing on clients without secret values.
local issecretvalue = _G.issecretvalue
local canaccesstable = _G.canaccesstable

local select, type, pcall, unpack = select, type, pcall, unpack

-- True when v is a secret value. An error while checking counts as secret.
function S.IsSecret(v)
    if issecretvalue == nil then return false end
    local ok, result = pcall(issecretvalue, v)
    if not ok then return true end
    return result == true
end

-- True when any of the given values is secret.
function S.AnySecret(...)
    for i = 1, select("#", ...) do
        if S.IsSecret((select(i, ...))) then return true end
    end
    return false
end

-- v itself when it is usable (not nil and not secret), otherwise nil.
function S.Value(v)
    if v == nil or S.IsSecret(v) then return nil end
    return v
end

-- Typed accessors: the value when it is not secret and has the expected type, else nil.
function S.Number(v)
    if S.IsSecret(v) or type(v) ~= "number" then return nil end
    return v
end

function S.String(v)
    if S.IsSecret(v) or type(v) ~= "string" then return nil end
    return v
end

function S.Boolean(v)
    if S.IsSecret(v) or type(v) ~= "boolean" then return nil end
    return v
end

-- t when it is a table whose fields may be read, else nil.
function S.Table(t)
    if S.IsSecret(t) or type(t) ~= "table" then return nil end
    if canaccesstable ~= nil then
        local ok, allowed = pcall(canaccesstable, t)
        if not ok or allowed ~= true then return nil end
    end
    return t
end

-- Field t[key] through S.Value; nil when t or the field is not usable.
function S.Field(t, key)
    t = S.Table(t)
    if not t then return nil end
    local ok, v = pcall(function() return t[key] end)
    if not ok then return nil end
    return S.Value(v)
end

local function Pack(...)
    return { n = select("#", ...), ... }
end

local function StripStatus(ok, ...)
    if not ok then return end
    return ...
end

-- Calls fn(...) protected. Returns its results, or nothing when fn is missing or fails.
-- Results may still be secret; use S.CallClean when they are compared or shown.
function S.Call(fn, ...)
    if type(fn) ~= "function" then return end
    return StripStatus(pcall(fn, ...))
end

-- Like S.Call, but every secret result is replaced by nil.
function S.CallClean(fn, ...)
    if type(fn) ~= "function" then return end
    local r = Pack(pcall(fn, ...))
    if not r[1] then return end
    for i = 2, r.n do
        if S.IsSecret(r[i]) then r[i] = nil end
    end
    return unpack(r, 2, r.n)
end

-- Calls obj:method(...) protected with secret results replaced by nil.
function S.Method(obj, method, ...)
    if obj == nil or S.IsSecret(obj) then return end
    local ok, fn = pcall(function() return obj[method] end)
    if not ok or type(fn) ~= "function" then return end
    return S.CallClean(fn, obj, ...)
end

-- True when the frame may be touched by addon code (exists and is not forbidden).
function S.FrameUsable(frame)
    if frame == nil or S.IsSecret(frame) then return false end
    local forbidden = S.Method(frame, "IsForbidden")
    return forbidden ~= true
end
