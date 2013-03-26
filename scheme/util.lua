local _M = {}

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

function _M.wrap(fun)
    return function (env, ...)
        local args = {}
        for _, a in ipairs({ ... }) do
            table.insert(args, env:_eval(a))
        end
        return fun(unpack(args))
    end
end

return _M

