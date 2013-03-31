local pairs = pairs
local getmetatable = getmetatable
local setmetatable = setmetatable
local rawget = rawget
local type = type
local tostring = tostring
local unpack = unpack
local table = table

local util = require("scheme.util")

-- Here I define global Scheme environment. Environments can nest into each
-- other, and global environment is the root one, the ancestor to all of them.
--
-- Actually an environment is just a table, so nothing can stop you to create
-- empty environment not connected to global environment, and use it to
-- evaluate parsed Scheme expressions, but this is a bad idea, trust me (unless
-- you really know what you are doing).
--
-- There're a number of utility methods an environment has to evaluate
-- expressions in it, create new sub-environment or add some syntax definitions
-- into it.
--
-- As all Scheme definitions go into the same environment, and these utility
-- methods are just simple table values, one can rewrite or override one of
-- such special methods either in global environment or in some
-- sub-environment. To avoid such situations, I set an agreement: all special
-- utility methods have two underscores at the start of their names, and you
-- never ever name your functions, variables etc. with names starting with
-- underscore.
--
-- Again.
--
-- ALL NAMES STARTING WITH TWO UNDERSCORES ARE RESERVED. DO NOT USE DOUBLE
-- UNDERSCORE AS THE FIRST CHARACTERS OF A NAME OF ANY OF YOUR USER-DEFINED
-- THINGS. EVER.
--
-- Thank you.

local _M = { "global" }

-- Returns outer environment or nil for global environment
function _M.__outer(env)
    local result = getmetatable(env).__index
    return type(result) == "table" and result or nil
end

-- Find an environment with given variable defined
-- Starts search from current environment and goes up the chain.
-- Returns environment the variable is found in, or nil if
-- no variable with such name is found.
--
-- @param string var
-- @return environment
function _M.__find(env, var)
    local _env = env
    while _env do
        if rawget(_env, var) then return _env end
        _env = _env:__outer()
    end
    return
end

-- Create new sub-environment
local envno = 0
function _M.__new(outer)
    envno = envno + 1
    return setmetatable({ "local" .. envno }, { __index = outer or _M })
end

-- Add definitions into environment
-- @param table
function _M.__define(env, defs)
    for name, body in pairs(defs) do
        env[name] = body
    end
end

-- Recursively import given things into environment
--
-- This methods is for importing things from Lua to Scheme land.
-- It goes down all tables recursively, flatting out names on
-- the road (e.g. { a = { b = { c = 3 } } } will create
-- "a.b.c" definition with value of 3 in the environment).
--
-- Also this method assumes all functions are not aware of Scheme
-- agreement of passing current environment as the first parameter,
-- so it wraps each met function into another function to support
-- this API.
--
-- Otherwise its clever and recursive behavior, this method
-- is very similar to _define() method above.
--
-- @param table defs
function _M.__import(env, defs, prefix)
    for name, body in pairs(defs) do
        if prefix then name = prefix .. "." .. name end

        if type(body) == "function" then
            body = util.wrap(body)
        elseif type(body) == "table" then
            env:__import(body, name)
        end

        env[name] = body
    end
end

-- Evaluate given parsed expressions in context of current environment
-- This is the main method of Scheme module, the heart of whole system.
-- It evaluates each given expression and returns the last expression
-- evaluation result.
--
-- @param expression...
-- @return mixed
function _M.__eval(env, token)
    if not token then return token end

    local token_type = type(token)

    if token_type == "string" then
        return env[token]
    end

    if token_type == "table" then
        return env:__eval(token[1])(env, unpack(token, 2))
    end

    return token
end

function _M.__evalall(env, args)
    for i, arg in ipairs(args) do
        args[i] = env:__eval(arg)
    end
    return args
end

local function split(string, sep)
    local result = {}
    local pos = 1

    while true do
        local s, e = string:find(sep, pos, true)
        if not s then
            table.insert(result, string:sub(pos))
            break
        end

        table.insert(result, string:sub(pos, s - 1))
        pos = e + 1
    end

    return result
end

local function setsubtable(tbl, name, value)
    name = split(name, ".")
    if type(tbl) ~= "table" then return end

    for i = 1, #name - 1 do
        local subtbl = tbl[name[i]]
        if type(subtbl) ~= "table" then
            subtbl = {}
            tbl[name[i]] = subtbl
        end
        tbl = subtbl
    end

    tbl[name[#name]] = value
    return tbl
end

function _M.__export(env, table)
    table = table or _G
    for k, v in pairs(env) do
        if type(v) ~= "function" then
            setsubtable(table, k, v)
        end
    end
    return table
end

setmetatable(_M, {
    __index = function (env, key)
        -- handle binding resolution failure
        local value = rawget(env, key)
        if value == nil then env:error("Unbound symbol: '" .. tostring(key) .. "'") end
        return value
    end
})

return _M
