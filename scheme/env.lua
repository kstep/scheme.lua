local util = require("scheme.util")

-- Here I define global Scheme environment.
-- Environments can nest into each other, and global
-- environment is the root one, the ancestor to all of them.
--
-- Actually an environment is just a table, so nothing can
-- stop you to create empty environment not connected to
-- global environment, and use to evaluate parsed Scheme
-- expressions, but this is a bad idea, trust me (unless
-- you really know what you are doing).
--
-- There're a number of utility methods an environment
-- has to evaluate expressions in it, create new sub-environment
-- or add some syntax definitions into it.
--
-- As all Scheme definitions go into the same environment,
-- and these utility methods are just simple table values,
-- one can rewrite or override one of such special methods
-- either in global environment or in some sub-environment.
-- To avoid such situations, I set an agreement:
-- all special utility methods have underscore at the start
-- of their names, and you never ever name your functions,
-- variables etc. with names starting with underscore.
--
-- Again.
--
-- ALL NAMES STARTING WITH AN UNDERSCORE ARE RESERVED.
-- DO NOT USE UNDERSCORE AS THE FIRST CHARACTER OF A NAME OF ANY
-- OF YOUR USER-DEFINED THINGS. EVER.

local _M = {}

-- Returns outer environment or nil for global environment
function _M._outer(env)
    return getmetatable(env).__index
end

-- Find an environment with given variable defined
-- Starts search from current environment and goes up the chain.
-- Returns environment the variable is found in, or nil if
-- no variable with such name is found.
--
-- @param string var
-- @return environment
function _M._find(env, var)
    local _env = env
    while _env do
        if rawget(_env, var) then return _env end
        _env = _env:_outer()
    end
    return
end

-- Create new sub-environment
function _M._new(outer)
    return setmetatable({}, { __index = outer or _M })
end

-- Add definitions into environment
-- @param table
function _M._define(env, defs)
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
function _M._import(env, defs, prefix)
    for name, body in pairs(defs) do
        if prefix then name = prefix .. "." .. name end

        if type(body) == "function" then
            body = util.wrap(body)
        elseif type(body) == "table" then
            env:_import(body, name)
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
function _M._eval(env, token)
    if not token then return end

    local token_type = type(token)

    if token_type == "string" then
        return env[token]
    end

    if token_type == "table" then
        return env:_eval(token[1])(env, unpack(token, 2))
    end

    return token
end

setmetatable(_M, {
    __index = function (env, key)
        -- handle binding resolution failure
        return rawget(env, key) or error("Error: unbound symbol: '" .. tostring(key) .. "'")
    end
})

return _M
