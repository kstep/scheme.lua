local ipairs = ipairs
local type = type
local unpack = unpack
local table = table

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
                list[1] = env:__eval(list[1])

                for i = 2, #list do
                    list[i] = env:__eval(list[i])
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
    local _env = env:__new()
    for _, binding in ipairs(defs) do
        _env[binding[1]] = env:__eval(binding[2])
    end

    return _env:begin(...)
end

local function named_let(env, name, defs, ...)
    local argnames = {}
    local args = {}
    for i, pair in ipairs(defs) do
        -- We don't need to eval args here, lambda will do it for us
        argnames[i], args[i] = unpack(pair)
    end

    local _env = env:__new()
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
        return type(env:__eval(arg)) == "string"
    end,
    ["number?"] = function (env, arg)
        return type(env:__eval(arg)) == "number"
    end,
    ["boolean?"] = function (env, arg)
        return type(env:__eval(arg)) == "boolean"
    end,
    ["lambda?"] = function (env, arg)
        return type(env:__eval(arg)) == "function"
    end,
    ["list?"] = function (env, arg)
        return type(env:__eval(arg)) == "table"
    end,

    ["pair?"] = function (env, arg)
        local val = env:__eval(arg)
        return type(val) == "table" and #val > 0
    end,

    ["null?"] = function (env, arg)
        local val = env:__eval(arg)
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
        local result = { ... }
        for i, expr in ipairs(result) do
            result[i] = env:__eval(expr)
        end
        return result
    end,
    -- }}}

    -- Flow control {{{
    cond = function (env, ...)
        for _, pair in ipairs({ ... }) do
            local test, expr = unpack(pair)
            if test == "else" or env:__eval(test) then
                return env:__eval(expr)
            end
        end
    end,

    ["if"] = function (env, cond, yes, no)
        return env:__eval(env:__eval(cond) and yes or no)
    end,

    begin = function (env, ...)
        local exprs = { ... }
        for i = 1, #exprs - 1 do
            if type(exprs[i]) == "table" then
                env:__eval(exprs[i])
            end
        end
        return env:__eval(exprs[#exprs])
    end,

    include = function (env, filename)
        return env:__eval(compile.file(env:__eval(filename)))
    end,

    values = function (env, ...)
        return unpack(env:list(...))
    end,
    -- }}}

    -- Classic list operations {{{
    car = function (env, expr)
        local val = env:__eval(expr)
        return assert(val and val[1], "Error: Attempt to apply car on nil")
    end,

    cdr = function (env, expr)
        return { unpack(env:__eval(expr), 2) }
    end,

    cons = function (env, head, tail)
        head = env:__eval(head)
        tail = env:__eval(tail)

        if type(tail) ~= "table" then
            tail = { tail }
        end

        if not head or (type(head) == "table" and #head == 0) then
            return tail
        end

        return { head, unpack(tail) }
    end,
    -- }}}

    -- Boolean operations {{{
    ["or"] = function (env, ...)
        local val = false
        for _, v in ipairs({ ... }) do
            val = env:__eval(v)
            if val then return val end
        end
        return val
    end,

    ["and"] = function (env, ...)
        local val = true
        for _, v in ipairs({ ... }) do
            val = env:__eval(v)
            if not val then return val end
        end
        return val
    end,

    ["not"] = function (env, expr)
        return not env:__eval(expr)
    end,
    -- }}}

    -- Assignment {{{
    define = function (env, key, ...)
        if type(key) == "table" then
            value = env:lambda({ unpack(key, 2) }, ...)
            key = key[1]
        else
            value = env:__eval(...)
        end

        env[key] = value
        return value
    end,

    ["set!"] = function (env, key, value)
        local val = env:__eval(value)
        local _env = env:__find(key) or env
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
        local _env = env:__new()
        for _, binding in ipairs(defs) do
            _env[binding[1]] = _env:__eval(binding[2])
        end

        return _env:begin(...)
    end,
    -- }}}

    -- Basic syntactic constructions {{{
    lambda = function (env, argnames, ...)
        local body = { "begin", ... }
        if #body < 3 then
            body = body[2]
        end

        return body and function (cenv, ...)
            local args = { ... }

            if #argnames ~= #args then
                error("Error: " .. list_dump(body) .. ": wrong number of arguments (expected: " .. #argnames .. " got: " .. #args .. ")")
            end

            local _env = env:__new()
            for i, a in ipairs(argnames) do
                _env[a] = cenv:__eval(args[i])
            end
            return _env:__eval(body)
        end
    end,

    quote = function (env, arg)
        return arg
    end,

    string = function (env, arg)
        return tostring(arg)
    end,

    apply = function (env, fn, ...)
        local args = { ... }

        for i, arg in ipairs(args) do
            args[i] = env:__eval(arg)
        end

        if type(args[#args]) == "table" then
            args = #args == 1 and args[1] or { unpack(args, 1, #args - 1), unpack(args[#args]) }
        end

        return env:__eval(fn)(env, unpack(args))
    end
    -- }}}
}

-- letrec and let* are the same due to Lua nature,
-- so we just make letrec an alias to let* for compatibility
_M["letrec"] = _M["let*"]

return _M
