local error = error

local list_dump = require("scheme.util").list_dump

return {
    error = function (env, reason)
        error("Error: " .. list_dump(reason))
    end,

    warn = function (env, reason)
        print("Warning: " .. list_dump(reason))
    end,

    ["with-handlers"] = function (env, handlers, ...)
        local ok, result = pcall(env.begin, env, ...)
        if ok then return result end

        result = {"quote", result}
        for _, pair in ipairs(handlers) do
            local predicate, handler = unpack(pair)
            if env:__eval(predicate)(env, result) then
                return env:__eval(handler)(env, result)
            end
        end

        error(result)
    end,
}
