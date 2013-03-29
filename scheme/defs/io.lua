local io = io
local print = print

local list_dump = require("scheme.util").list_dump
local compile = require("scheme.compile")

return {
    print = function (env, expr)
        print(list_dump(env:_eval(expr)))
    end,

    display = function (env, expr)
        io.write(list_dump(env:_eval(expr)))
    end,

    newline = function (env)
        print()
    end,

    read = function (env)
        return env:_eval(compile.string(io.read("*line")))
    end,
}
