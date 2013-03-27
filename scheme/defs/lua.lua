
return {
    -- Load Lua code into string
    -- @return function which executes Lua code
    ["lua-load"] = function (env, code)
        return loadstring("return " .. env:_eval(code))
    end,

    -- Import Lua module into Scheme land
    ["lua-import"] = function (env, module)
        env:_import({ [module] = require(module) })
    end,

    -- Create Lua table out of key-value pairs
    -- @example (table [(key value)]...)
    table = function (env, ...)
        local result = {}
        for _, pair in ipairs({ ... }) do
            result[pair[1]] = env:_eval(pair[2])
        end
        return result
    end,

    -- Get value from Lua table
    -- @example (table-get tbl key)
    ["table-get"] = function (env, table, name)
        return env:_eval(table)[name]
    end,

    -- Set value in Lua table by key
    -- @example (table-set! tbl key expr)
    ["table-set!"] = function (env, table, name, expr)
        local value = env:_eval(expr)
        env:_eval(table)[name] = value
        return value
    end
}
