local io = io
local print = print

local list_dump = require("scheme.util").list_dump
local compile = require("scheme.compile")

return {
    print = function (env, expr)
        print(list_dump(env:__eval(expr)))
    end,

    display = function (env, expr)
        io.write(list_dump(env:__eval(expr)))
    end,

    newline = function (env)
        print()
    end,

    read = function (env, file)
        return compile.string((env:__eval(file) or io.input()):read("*line"))
    end,

    ["open-file"] = function (env, filename, mode)
        return io.open(env:__eval(filename), env:__eval(mode))
    end,
    close = function (env, file)
        return env:__eval(file):close()
    end,
}
