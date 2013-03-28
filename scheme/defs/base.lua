local math = require("scheme.defs.math")
local compile = require("scheme.compile")
local list_dump = require("scheme.util").list_dump

-- Compare tables recursively, as defined in equal? Scheme specs
local function table_equal(tbl1, tbl2)
    if tbl1 == tbl2 then return true end
    if type(tbl1) ~= "table" or type(tbl2) ~= "table" or #tbl1 ~= #tbl2 then return false end

    for i = 1, #tbl1 do
        if not table_equal(tbl1[i], tbl2[i]) then return false end
    end

    return true
end

local function equal(var1, var2)
    if var1 ~= var2 then return false end
    -- According to Scheme specs, two empty tables are equal in regard to eqv? and eq? forms
    if type(tbl1) == "table" and type(tbl2) == "table" and #tbl1 == 0 and #tbl2 == 0 then return true end
    return true
end

-- Memoized version of high-order function to generate function to check if all
-- elements in a list are equal to each other according to some given
-- comparison function
local all_equal = (function ()
    local memoized = {}
    return function (eqv)
        if not memoized[eqv] then
            memoized[eqv] = function (env, ...)
                local list = { ... }
                -- Notice we evaluate each item in the input list only once,
                -- and we evaluate only as little elements as possible
                -- to check if at least one item in the list is not equal
                -- to all other items. Hence we have O(n) calls to eval()
                -- in worst case.
                list[1] = env:_eval(list[1])

                for i = 2, #list do
                    list[i] = env:_eval(list[i])
                    -- The eqv function is called once for each item in the
                    -- input list minus one, hence this loop has complexity of
                    -- O(n - 1) in regard of eqv() calls. Total loop complexity
                    -- depends on eqv() complexity, which can be either O(1)
                    -- for simple checks or about O(log(n)) for in-depth
                    -- recursive comparisons.
                    if not eqv(list[i - 1], list[i]) then return false end
                end

                return true
            end
        end
        return memoized[eqv]
    end
end)()

local function let(env, defs, ...)
    local _env = env:_new()
    for _, binding in ipairs(defs) do
        _env[binding[1]] = env:_eval(binding[2])
    end

    return _env:begin(...)
end

local function named_let(env, name, defs, ...)
    local argnames = {}
    local args = {}
    for _, pair in ipairs(defs) do
        table.insert(argnames, pair[1])
        -- We don't need to eval args here, lambda will do it for us
        table.insert(args, pair[2])
    end

    local _env = env:_new()
    local fn = _env:lambda(argnames, ...)
    _env[name] = fn
    return fn(_env, unpack(args))
end

local function void()
    return nil
end

local _M = {
    -- Special constants {{{
    -- I should have convert it to nil during compilation stage,
    -- but nil is a special thing in Lua used as a marker to
    -- stop iteration, and as compiler uses iterators, I can't
    -- use nil as the result of compilation, hence I evaluate
    -- this constant to nil later.
    ["#<void>"] = void,
    ["void"] = void,
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

    ["pair?"] = function (env, arg)
        local val = env:_eval(arg)
        return type(val) == "table" and #val > 0
    end,

    ["null?"] = function (env, arg)
        local val = env:_eval(arg)
        return type(val) == "table" and #val == 0
    end,

    ["eq?"] = all_equal(equal),
    ["eqv?"] = all_equal(equal),
    ["equal?"] = all_equal(table_equal),
    -- }}}

    -- Type constructors {{{
    string = function (env, ...)
        return table.concat({ ... }, " ")
    end,

    list = function (env, ...)
        local result = {}
        for _, expr in ipairs({ ... }) do
            table.insert(result, env:_eval(expr))
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
        return env:_eval(compile.file(env:_eval(filename)))
    end,

    values = function (env, ...)
        return unpack(env:list(...))
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
        local list = env:_eval(head)
        tail = env:_eval(tail)

        if type(list) ~= "table" then
            list = { list }
        end

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
        local val = false
        for _, v in ipairs({ ... }) do
            val = env:_eval(v)
            if val then return val end
        end
        return val
    end,

    ["and"] = function (env, ...)
        local val = true
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

    -- Input/output {{{
    print = function (env, expr)
        print(list_dump(env:_eval(expr)))
    end,

    display = function (env, expr)
        io.write(list_dump(env:_eval(expr)))
    end,

    newline = function (env)
        print()
    end,
    -- }}}

    -- Assignment {{{
    define = function (env, key, ...)
        if type(key) == "table" then
            local argnames = key
            key = key[1]
            table.remove(argnames, 1)

            value = env:lambda(argnames, ...)
        else
            local expr = ...
            value = env:_eval(expr)
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

    let = function (env, defs, ...)
        if type(defs) == "table" then -- normal let
            return let(env, defs, ...)

        elseif type(defs) == "string" then -- named let
            return named_let(env, defs, ...)

        else -- error
            error("Error: Missing expression")
        end
    end,

    ["let*"] = function (env, defs, ...)
        local _env = env:_new()
        for _, binding in ipairs(defs) do
            _env[binding[1]] = _env:_eval(binding[2])
        end

        return _env:begin(...)
    end,
    -- }}}

    -- Basic syntactic constructions {{{
    lambda = function (cenv, argnames, ...)
        local body = { ... }
        return function (env, ...)
            local args = { ... }
            local _env = cenv:_new()

            assert(#argnames == #args, "Error: " .. list_dump(body) .. ": wrong number of arguments (expected: " .. #argnames .. " got: " .. #args .. ")")

            local i, a
            for i, a in ipairs(argnames) do
                _env[a] = env:_eval(args[i])
            end
            return _env:begin(unpack(body))
        end
    end,

    quote = function (env, arg)
        return arg
    end,
    -- }}}
}

-- letrec and let* are the same due to Lua nature,
-- so we just make letrec an alias to let* for compatibility
_M["letrec"] = _M["let*"]

return _M
