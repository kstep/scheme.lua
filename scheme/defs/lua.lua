local ipairs = ipairs
local pairs = pairs
local table = table

local list_dump = require("scheme.util").list_dump

return {
    -- Load Lua code into string
    -- @return function which executes Lua code
    ["lua-load"] = function (env, code)
        return loadstring("return " .. env:__eval(code))
    end,

    -- Import Lua module into Scheme land
    ["lua-import"] = function (env, module)
        local result = require(module)
        env:__import({ [module] = result })
        return result
    end,

    -- Create Lua table out of key-value pairs
    -- @example (table [(key value)]...)
    table = function (env, ...)
        local result = {}
        for _, pair in ipairs({ ... }) do
            result[pair[1]] = env:__eval(pair[2])
        end
        return result
    end,

    -- Get value from Lua table
    -- @example (table-get tbl key)
    ["table-get"] = function (env, table, name)
        return env:__eval(table)[name]
    end,

    -- Get list of table keys
    -- @example (table-keys tbl)
    ["table-keys"] = function (env, expr)
        local result = {}
        for k, _ in pairs(env:__eval(expr)) do
            table.insert(result, k)
        end
        return result
    end,

    -- Get list of table values
    ["table-values"] = function (env, expr)
        local result = {}
        for _, v in pairs(env:__eval(expr)) do
            table.insert(result, v)
        end
        return result
    end,

    -- Convert table to a list of pairs
    ["table->list"] = function (env, expr)
        local result = {}
        for k, v in pairs(env:__eval(expr)) do
            table.insert(result, {k, v})
        end
        return result
    end,

    -- Predicate to test if given expression is a table
    ["table?"] = function (env, expr)
        local items = 0
        local tbl = env:__eval(expr)
        for k, _ in pairs(tbl) do
            if type(k) ~= "number" then
                return true
            end
            items = items + 1
        end
        return #tbl ~= items
    end,

    -- Get list of two lists: table keys and values
    ["table-keys-values"] = function (env, expr)
        local keys = {}
        local values = {}
        for k, v in pairs(env:__eval(expr)) do
            table.insert(keys, k)
            table.insert(values, v)
        end
        return {keys, values}
    end,

    -- Set value in Lua table by key
    -- @example (table-set! tbl key expr)
    ["table-set!"] = function (env, table, name, expr)
        local value = env:__eval(expr)
        env:__eval(table)[name] = value
        return value
    end,

    assert = function (env, expr)
        if not env:__eval(expr) then
            env:error("Assertion failed: " .. list_dump(expr))
        end
    end,
}
