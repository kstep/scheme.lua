local parse = require("scheme.parse")
local genv = require("scheme.env")
require("scheme.base")

local _M = {}

function _M.run(expr, env)
    env = env or genv
    return env:_eval(parse.string(expr))
end

function _M.runfile(file, env)
    env = env or genv
    return env:_eval(parse.file(file))
end

function _M.import(defs, env)
    env = env or genv
    return env:_import(defs)
end

function _M.define(defs, env)
    env = env or genv
    return env:_define(defs)
end

function _M.new(env)
    env = env or genv
    return env:_new()
end

local code_mt = {
    __index = {
        eval = _M.eval
    }
}

function _M.compile(expr)
    return setmetatable({ parse.string(expr) }, code_mt)
end

function _M.compilefile(file)
    return setmetatable({ parse.file(file) }, code_mt)
end

function _M.eval(code, env)
    env = env or genv
    return env:_eval(code)
end

return _M

