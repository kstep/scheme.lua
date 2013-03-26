local io = io
local table = table
local unpack = unpack
local math = math
local tostring = tostring
local setmetatable = setmetatable

_M = {}

local global_env = {}
function global_env._outer(env)
    return getmetatable(env).__index
end
setmetatable(global_env, {
    __index = function (env, key)
        return rawget(env, key) or error("Error: unbound symbol: '" .. tostring(key) .. "'")
    end
})

local function var_dump(var, level)
    local result = ""
    local level = level or 0
    local indent = ("    "):rep(level)

    if type(var) == "table" then
        result = result .. "{\n"
        for k, v in pairs(var) do
            result = result .. indent .. "[" .. k .. "] = " .. var_dump(v, level + 1)
        end
        result = result .. indent .. "}\n"
    elseif type(var) == "string" then
        result = result .. "\"" .. var .. "\"\n"
    elseif var == nil then
        result = result .. "nil\n"
    else
        result = result .. tostring(var) .. "\n"
    end

    return result
end
_M.var_dump = var_dump

local function list_dump(expr)
    if type(expr) == "function" then
        return "#<Closure>"

    elseif type(expr) == "table" then
        local result = " "
        for _, v in ipairs(expr) do
            result = result .. " " .. list_dump(v)
        end
        result = "(" .. result:sub(3) .. ")"
        return result

    elseif type(expr) == "string" then
        return expr:find("%s") and "\"" .. expr:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\"" or expr

    elseif type(expr) == "boolean" then
        return expr and "#t" or "#f"

    else
        return tostring(expr)
    end
end
_M.list_dump = list_dump

local function eval(env, ...)
    if not env then env = global_env end

    local result
    for _, token in ipairs({ ... }) do
        if type(token) == "function" then
            result = token(env)

        elseif type(token) == "boolean" then
            result = token

        elseif type(token) == "table" then
            local fun = env:_eval(token[1])
            assert(type(fun) == "function", "Error: " .. list_dump(fun) .. " is not a function")

            local args = {}
            for i = 2, #token do table.insert(args, token[i]) end
            result = fun(env, unpack(args))

        else
            result = tonumber(token) or env[token]
        end
    end

    return result
end
_M.eval = function (token, env) return eval(env or global_env, token) end

local function find_env(env, var)
    local _env = env
    while _env do
        if rawget(_env, var) then return _env end
        _env = getmetatable(_env)["__index"]
    end
    return
end

local function wrap_function(fun)
    return function (env, ...)
        local args = {}
        for _, a in ipairs({ ... }) do
            table.insert(args, env:_eval(a))
        end
        return fun(unpack(args))
    end
end
_M.wrap = wrap_function

local function define(env, defs)
    for name, body in pairs(defs) do
        env[name] = body
    end
end
_M.define = function (defs, env) return define(env or global_env, defs) end

local function new(outer)
    return setmetatable({}, { __index = outer or global_env })
end
_M.new = new

global_env._new = new
global_env._eval = eval
global_env._find = find_env
global_env._define = define

global_env:_define {
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
            div = div / eval(env, arg[i])
        end
        return div
    end,

    div = function (env, a, b)
        return math.floor(env:_eval(a) / env:_eval(b))
    end,

    mod = function (env, a, b)
        return env:_eval(a) % env:_eval(b)
    end,

    ["eval-lua"] = function (env, code)
        return loadstring("return " .. env:_eval(code))()
    end,

    string = function (env, ...)
        return table.concat({ ... }, " ")
    end,

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

    table = function (env, ...)
        local result = {}
        for _, pair in ipairs({ ... }) do
            result[pair[1]] = env:_eval(pair[2])
        end
        return result
    end,

    cond = function (env, ...)
        for _, pair in ipairs({ ... }) do
            local test, expr = unpack(pair)
            if test == "else" or env:_eval(test) then
                return env:_eval(expr)
            end
        end
    end,

    car = function (env, expr)
        local val = env:_eval(expr)
        assert(val and val[1], "Error: Attempt to apply car on nil")
        return val[1]
    end,

    ["if"] = function (env, cond, yes, no)
        if env:_eval(cond) then
            return env:_eval(yes)
        else
            return env:_eval(no)
        end
    end,

    ["or"] = function (env, ...)
        local val
        for _, v in ipairs({ ... }) do
            val = env:_eval(v)
            if val then return true end
        end
        return false
    end,

    ["and"] = function (env, ...)
        local val
        for _, v in ipairs({ ... }) do
            val = env:_eval(v)
            if not val then return false end
        end
        return true
    end,

    ["null?"] = function (env, expr)
        return #env:_eval(expr) == 0
    end,

    cdr = function (env, expr)
        expr = env:_eval(expr)
        local rest = {}
        for i = 2, #expr do
            table.insert(rest, expr[i])
        end
        return rest
    end,

    quote = function (env, ...)
        return { ... }
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

    print = function (env, expr)
        print(list_dump(env:_eval(expr)))
    end,

    display = function (env, expr)
        io.write(list_dump(env:_eval(expr)))
    end,

    length = function (env, expr)
        return #env:_eval(expr)
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

    lambda = function (env, argnames, body)
        return function (env, ...)
            local args = { ... }
            local _env = env:_new()

            assert(#argnames == #args, "Error: " .. list_dump(body) .. ": wrong number of arguments (expected: " .. #argnames .. " got: " .. #args .. ")")

            local i, a
            for i, a in ipairs(argnames) do
                _env[a] = env:_eval(args[i])
            end
            return _env:_eval(body)
        end
    end,

    begin = function (env, ...)
        local result
        for _, expr in ipairs({ ... }) do
            result = env:_eval(expr)
        end
        return result
    end,

    ["="] = function (env, ...)
        local exprs = { ... }

        exprs[1] = env:_eval(exprs[1])
        for i = 2, #exprs do
            exprs[i] = env:_eval(exprs[i])
            if exprs[i - 1] ~= exprs[i] then return false end
        end

        return true
    end,

    ["not"] = function (env, expr)
        return not env:_eval(expr)
    end,
}

local function token(expr)
    local s, e = expr:find("^%s+")
    if s then
        expr = expr:sub(e + 1)
    end

    local ch = expr:sub(1, 1)

    if ch == "(" or ch == "[" then
        return "(", expr:sub(2)

    elseif ch == ")" or ch == "]" then
        return ")", expr:sub(2)

    elseif expr:sub(1, 2) == "'(" then
        return token("(quote " .. expr:sub(3))

    elseif ch == "\"" then
        local s, e
        local i = 2
        local r = ""
        while true do
            s, e = expr:find("[\\\"]", i)
            assert(s, "Syntax error: Missing closing quote")

            if expr:sub(s, e) == "\\" then
                r = r .. expr:sub(i, s - 1) .. expr:sub(e + 1, e + 1)
                i = e + 2
            else
                r = r .. expr:sub(i, s - 1)
                return r, expr:sub(e + 1)
            end
        end

    elseif ch == ";" or expr:sub(1, 2) == "#!" then
        local s, e = expr:find("\n")
        if not s then return nil, "" end
        return token(expr:sub(e + 1))

    elseif expr:sub(1, 2) == "#|" then
        local s, e = expr:find("|#")
        assert(s, "Syntax error: Missing long comment end")
        return token(expr:sub(e + 1))

    else
        t = expr:match("^[^][(%s)]+")
        if t then
            return t, expr:sub(1 + t:len())
        else
            return nil, expr
        end
    end
end

local function tokenize(expr)
    local state = expr
    return function ()
        local t
        t, state = token(state)
        return t
    end
end
_M.tokenize = tokenize

local function parse(tokens)
    local result = {}
    if type(tokens) == "string" then
        tokens = tokenize(tokens)
    end

    for t in tokens do
        if t == "(" then
            table.insert(result, parse(tokens))

        elseif t == ")" then
            if type(result) ~= "table" then
                error("Syntax error: Unbalanced parenthesis")
            end
            return result

        elseif t == "#f" then
            table.insert(result, false)

        elseif t == "#t" then
            table.insert(result, true)

        elseif t == "." then
            -- skip
    
        elseif t:sub(1, 2) == "#i" then
            table.insert(result, tonumber(t:sub(3)) or t)

        else
            table.insert(result, t)
        end
    end

    return unpack(result)
end
_M.parse = parse

local function parsefile(file)
    local fh = io.open(file, "r")
    assert(fh, "Error: Can not open file '" .. file .. "'")
    return parse(fh:read("*all"))
end
_M.parsefile = parsefile

local function run(expr, env)
    return eval(env or global_env, parse(expr))
end
_M.run = run

local function runfile(file, env)
    return eval(env or global_env, parsefile(file))
end
_M.runfile = runfile

global_env:_define {
    include = function (env, filename)
        return env:_eval(parsefile(filename))
    end,
}

return _M
