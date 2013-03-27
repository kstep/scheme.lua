local util = require("scheme.util")

local _M = {}

function _M._outer(env)
    return getmetatable(env).__index
end

function _M._find(env, var)
    local _env = env
    while _env do
        if rawget(_env, var) then return _env end
        _env = _env:_outer()
    end
    return
end

function _M._new(outer)
    return setmetatable({}, { __index = outer or _M })
end

function _M._define(env, defs)
    for name, body in pairs(defs) do
        env[name] = body
    end
end

function _M._import(env, defs, prefix)
    for name, body in pairs(defs) do
        if prefix then name = prefix .. "." .. name end

        if type(body) == "function" then
            body = util.wrap(body)
        elseif type(body) == "table" then
            env:_import(body, name)
        end

        env[name] = body
    end
end

function _M._eval(env, ...)
    if not env then env = _M end

    local result
    for _, token in ipairs({ ... }) do
        local token_type = type(token)

        if token_type == "boolean" or token_type == "number" or token_type == "nil" then
            result = token

        elseif token_type == "table" then
            local fun = env:_eval(token[1])
            assert(type(fun) == "function", "Error: " .. util.list_dump(fun) .. " is not a function")

            local args = {}
            for i = 2, #token do table.insert(args, token[i]) end
            result = fun(env, unpack(args))

        elseif token_type == "function" then
            result = token(env)

        elseif token_type == "string" then
            if token:sub(1, 1) == "\"" then
                result = token:sub(2)
            else
                result = env[token]
            end

        else
            error("Error: unexpected token type: '" .. token_type "'")
        end
    end

    return result
end

setmetatable(_M, {
    __index = function (env, key)
        return rawget(env, key) or error("Error: unbound symbol: '" .. tostring(key) .. "'")
    end
})

return _M
