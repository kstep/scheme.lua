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

return _M

