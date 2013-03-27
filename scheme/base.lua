local genv = require("scheme.env")
local parse = require("scheme.parse")
local list_dump = require("scheme.util").list_dump

local _M = {}

genv:_define {
    -- Basic arithmetic {{{
    ["+"] = function (env, ...)
        local arg = { ... }
        sum = env:_eval(arg[1]) or 0
        for i = 2, #arg do
            sum = sum + env:_eval(arg[i])
        end
        return sum
    end,

    ["-"] = function (env, ...)
        local arg = { ... }
        dif = env:_eval(arg[1]) or 0
        for i = 2, #arg do
            dif = dif - env:_eval(arg[i])
        end
        return dif
    end,

    ["*"] = function (env, ...)
        local arg = { ... }
        mul = env:_eval(arg[1]) or 1
        for i = 2, #arg do
            mul = mul * env:_eval(arg[i])
        end
        return mul
    end,

    ["/"] = function (env, ...)
        local arg = { ... }
        div = env:_eval(arg[1]) or 1
        for i = 2, #arg do
            div = div / env:_eval(arg[i])
        end
        return div
    end,

    div = function (env, a, b)
        return math.floor(env:_eval(a) / env:_eval(b))
    end,

    mod = function (env, a, b)
        return env:_eval(a) % env:_eval(b)
    end,
    -- }}}

    -- Type predicates {{{
    ["string?"] = function (env, arg)
        return type(env:_eval(arg)) == "string"
    end,
    ["number?"] = function (env, arg)
        return type(env:_eval(arg)) == "number"
    end,
    ["boolean?"] = function (env, arg)
        return type(env:_eval(arg)) == "boolean"
    end,
    ["lambda?"] = function (env, arg)
        return type(env:_eval(arg)) == "function"
    end,
    ["list?"] = function (env, arg)
        return type(env:_eval(arg)) == "table"
    end,
    -- }}}

    -- Type constructors {{{
    string = function (env, ...)
        return table.concat({ ... }, " ")
    end,

    table = function (env, ...)
        local result = {}
        for _, pair in ipairs({ ... }) do
            result[pair[1]] = env:_eval(pair[2])
        end
        return result
    end,
    -- }}}

    -- Flow control {{{
    cond = function (env, ...)
        for _, pair in ipairs({ ... }) do
            local test, expr = unpack(pair)
            if test == "else" or env:_eval(test) then
                return env:_eval(expr)
            end
        end
    end,

    ["if"] = function (env, cond, yes, no)
        if env:_eval(cond) then
            return env:_eval(yes)
        else
            return env:_eval(no)
        end
    end,

    begin = function (env, ...)
        local result
        for _, expr in ipairs({ ... }) do
            result = env:_eval(expr)
        end
        return result
    end,

    include = function (env, filename)
        return env:_eval(parse.file(env:_eval(filename)))
    end,
    -- }}}

    -- Classic list operations {{{
    car = function (env, expr)
        local val = env:_eval(expr)
        assert(val and val[1], "Error: Attempt to apply car on nil")
        return val[1]
    end,

    cdr = function (env, expr)
        expr = env:_eval(expr)
        local rest = {}
        for i = 2, #expr do
            table.insert(rest, expr[i])
        end
        return rest
    end,

    cons = function (env, head, tail)
        local list = { env:_eval(head) }
        tail = env:_eval(tail)

        if type(tail) == "table" then
            for _, v in ipairs(tail) do
                table.insert(list, v)
            end
        else
            table.insert(list, tail)
        end
        return list
    end,
    -- }}}

    -- Boolean operations {{{
    ["or"] = function (env, ...)
        local val
        for _, v in ipairs({ ... }) do
            val = env:_eval(v)
            if val then return val end
        end
        return val
    end,

    ["and"] = function (env, ...)
        local val
        for _, v in ipairs({ ... }) do
            val = env:_eval(v)
            if not val then return val end
        end
        return val
    end,

    ["not"] = function (env, expr)
        return not env:_eval(expr)
    end,
    -- }}}

    -- Arithmetic predicates {{{
    ["="] = function (env, ...)
        local exprs = { ... }

        exprs[1] = env:_eval(exprs[1])
        for i = 2, #exprs do
            exprs[i] = env:_eval(exprs[i])
            if exprs[i - 1] ~= exprs[i] then return false end
        end

        return true
    end,

    [">"] = function (env, a, b)
        return env:_eval(a) > env:_eval(b)
    end,

    ["<"] = function (env, a, b)
        return env:_eval(a) < env:_eval(b)
    end,

    [">="] = function (env, a, b)
        return env:_eval(a) >= env:_eval(b)
    end,

    ["<="] = function (env, a, b)
        return env:_eval(a) <= env:_eval(b)
    end,
    -- }}}

    -- Input/output {{{
    print = function (env, expr)
        print(list_dump(env:_eval(expr)))
    end,

    display = function (env, expr)
        io.write(list_dump(env:_eval(expr)))
    end,
    -- }}}

    -- Assignment {{{
    let = function (env, defs, ...)
        local _env = env:_new()
        for _, binding in ipairs(defs) do
            _env[binding[1]] = env:_eval(binding[2])
        end

        return _env:begin(...)
    end,

    ["let*"] = function (env, defs, ...)
        local _env = env:_new()
        for _, binding in ipairs(defs) do
            _env[binding[1]] = _env:_eval(binding[2])
        end

        return _env:begin(...)
    end,

    define = function (env, key, value)

        if type(key) == "table" then
            local argnames = key
            key = key[1]
            table.remove(argnames, 1)

            value = env:lambda(argnames, value)
        else
            value = env:_eval(value)
        end

        env[key] = value
        return value
    end,

    ["set!"] = function (env, key, value)
        local val = env:_eval(value)
        local _env = env:_find(key) or env
        _env[key] = val
        return val
    end,
    -- }}}

    -- Basic syntactic constructions {{{
    lambda = function (env, argnames, ...)
        local body = { ... }
        return function (env, ...)
            local args = { ... }
            local _env = env:_new()

            assert(#argnames == #args, "Error: " .. list_dump(body) .. ": wrong number of arguments (expected: " .. #argnames .. " got: " .. #args .. ")")

            local i, a
            for i, a in ipairs(argnames) do
                _env[a] = env:_eval(args[i])
            end
            return _env:begin(unpack(body))
        end
    end,

    quote = function (env, ...)
        return { ... }
    end,
    -- }}}

    -- Lua integration {{{
    ["lua-eval"] = function (env, code)
        return loadstring("return " .. env:_eval(code))()
    end,

    ["lua-import"] = function (env, module)
        env:_import({ [module] = require(module) })
    end,

    get = function (env, table, name)
        return env:_eval(table)[name]
    end,
    -- }}}

    -- Miscellaneous predicates {{{
    ["null?"] = function (env, expr)
        return #env:_eval(expr) == 0
    end,
    -- }}}
}

return _M
