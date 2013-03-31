local pairs = pairs
local setmetatable = setmetatable

local compile = require("scheme.compile")
local genv = require("scheme.env")
local defs = require("scheme.defs")

-- A number of front-end methods

local _M = {}

-- import all definitions
for _, def in pairs(defs) do
    genv:__define(def)
end

-- Parse and evaluate given expression in an environment
--
-- @param string expr
-- @param =env [global]
-- @return mixed
function _M.run(expr, env)
    env = env or genv
    return env:__eval(compile.string(expr))
end

-- The same as run() above, but loads code from a file
-- @see run()
function _M.runfile(file, env)
    env = env or genv
    return env:__eval(compile.file(file))
end

-- Import given definitions into an environment
-- @see scheme.env._import()
-- @param table defs
-- @param =env [global]
function _M.import(defs, env)
    env = env or genv
    return env:__import(defs)
end

-- Export all variables from environment to given Lua table
-- If you omit table name, it will export variables into
-- global variables table _G.
-- @param =table [_G]
-- @param =env [global]
-- @return table
function _M.export(table, env)
    env = env or genv
    return env:__export(table)
end

-- Add new definitions into an environment
-- @see scheme.env._define()
-- @param table defs
-- @param =env [global]
function _M.define(defs, env)
    env = env or genv
    return env:__define(defs)
end

-- Create a new environment with given environment as a base
-- @see scheme.env._new()
-- @param =env [global]
-- @return env
function _M.new(env)
    env = env or genv
    return env:__new()
end

-- Evaluate compiled code in given environment
-- @see scheme.env._eval()
-- @param parsed code
-- @param =env [global]
-- @return mixed evaluation result
function _M.eval(code, env)
    env = env or genv
    return env:__eval(code)
end

local code_mt = {
    __index = {
        eval = _M.eval
    }
}

-- Compile given expression
-- @param string expr
-- @return parsed expression
function _M.compile(expr)
    --return setmetatable(compile.string(expr), code_mt)
    return compile.string(expr)
end

-- The same as compile() above but for files
-- @see compile()
function _M.compilefile(file)
    --return setmetatable(compile.file(file), code_mt)
    return compile.file(file)
end

return _M

