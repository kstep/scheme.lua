
return {
    map = function (env, fn, ...)
        local args = env:_evalall({ ... })
        local fun = env:_eval(fn)
        local result = {}
        local index = 1

        while true do
            local set = {}
            for _, list in ipairs(args) do
                if not list[index] then
                    return result
                end
                table.insert(set, list[index])
            end
            table.insert(result, fun(env, unpack(set)))
            index = index + 1
        end

        return result
    end,

    zip = function (env, ...)
        return env:map(function (...) return { ... } end, ...)
    end,

}
