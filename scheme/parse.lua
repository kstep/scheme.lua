local _M = {}

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
                return "\"" .. r, expr:sub(e + 1)
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

        elseif t == "#f" or t == "#F" then
            table.insert(result, false)

        elseif t == "#t" or t == "#T" then
            table.insert(result, true)

        elseif t == "." then
            -- skip
    
        elseif t == "#<void>" or t == "#<undefined>" then
            table.insert(result, nil)

        else
            local chch = t:sub(1, 2)
            local base = nil

            if chch == "#i" or chch == "#e" then
                base = 10
            elseif chch == "#b" then
                base = 2
            elseif chch == "#o" then
                base = 8
            elseif chch == "#x" then
                base = 16
            end

            if base then t = t:sub(3) end
            table.insert(result, tonumber(t, base) or t)
        end
    end

    return unpack(result)
end
_M.string = parse

local function parsefile(file)
    local fh = io.open(file, "r")
    assert(fh, "Error: Can not open file '" .. file .. "'")

    return parse(fh:read("*all"))
end
_M.file = parsefile

return _M

