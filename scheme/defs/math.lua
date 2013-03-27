local math = math

return {
    -- Constants {{{
    pi = math.pi,
    e = math.exp(1),
    -- }}}

    ln = function (env, num)
        return math.log(env:_eval(num))
    end,
    log = function (env, num, base)
        return math.log(env:_eval(num), env:_eval(base))
    end,
    
    -- Trigonometry {{{
    sin = function (env, arg)
        return math.sin(env:_eval(arg))
    end,
    asin = function (env, arg)
        return math.asin(env:_eval(arg))
    end,

    cos = function (env, arg)
        return math.cos(env:_eval(arg))
    end,
    acos = function (env, arg)
        return math.acos(env:_eval(arg))
    end,

    tan = function (env, arg)
        return math.tan(env:_eval(arg))
    end,
    atan = function (env, arg)
        return math.atan(env:_eval(arg))
    end,
    atan2 = function (env, a, b)
        return math.atan2(env:_eval(a), env:_eval(b))
    end,
    -- }}}
}
