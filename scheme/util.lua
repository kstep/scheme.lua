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
    local expr_type = type(expr)

    if expr_type == "function" then
        return "#<Closure>"

    elseif expr_type == "table" then
        local result = " "
        for _, v in ipairs(expr) do
            result = result .. " " .. list_dump(v)
        end
        result = "(" .. result:sub(3) .. ")"
        return result

    elseif expr_type == "string" then
        return expr:sub(1, 1) == "\"" and "\"" .. expr:sub(2):gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\"" or expr

    elseif expr_type == "boolean" then
        return expr and "#t" or "#f"

    elseif expr_type == "nil" then
        return "#<void>"

    else
        if expr == 1/0 then
            return "+inf.0"
        elseif expr == -1/0 then
            return "-inf.0"
        elseif expr ~= expr then
            return "+nan.0"
        end

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

