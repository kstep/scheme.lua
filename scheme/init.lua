local pairs = pairs
local setmetatable = setmetatable

local compile = require("scheme.compile")
local genv = require("scheme.env")
local defs = require("scheme.defs")

-- A number of front-end methods

local _M = {}

local function eval(code, env)
    env = env or genv
    local ok, result = pcall(env.__eval, env, code)
    if ok then return result end
    
    return (type(result) == "table" and result[1] or env)["error-handler"](env, result)
end

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
    return eval(compile.string(expr), env)
end

-- The same as run() above, but loads code from a file
-- @see run()
function _M.runfile(file, env)
    return eval(compile.file(file), env)
end

-- Import given definitions into an environment
-- @see scheme.env._import()
-- @param table defs
-- @param =env [global]
function _M.import(defs, env)
    return (env or genv):__import(defs)
end

-- Export all variables from environment to given Lua table
-- If you omit table name, it will export variables into
-- global variables table _G.
-- @param =table [_G]
-- @param =env [global]
-- @return table
function _M.export(table, env)
    return (env or genv):__export(table)
end

-- Add new definitions into an environment
-- @see scheme.env._define()
-- @param table defs
-- @param =env [global]
function _M.define(defs, env)
    return (env or genv):__define(defs)
end

-- Create a new environment with given environment as a base
-- @see scheme.env._new()
-- @param =env [global]
-- @return env
function _M.new(env)
    return (env or genv):__new()
end

-- Evaluate compiled code in given environment
-- @see scheme.env._eval()
-- @param parsed code
-- @param =env [global]
-- @return mixed evaluation result
_M.eval = eval

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

