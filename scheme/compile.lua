local _M = {}

-- Extract token from expression string
-- @param string
-- @return token, rest of string
local function token(expr)
    local s, e = expr:find("^%s+")
    if s then
        expr = expr:sub(e + 1)
    end

    local ch = expr:sub(1, 1)

    -- I don't make a distinction between parenthesis and brackets,
    -- so you can open list with a bracket and close with a paren
    -- or vice versa. Consider it a syntax sugar =)
    if ch == "(" or ch == "[" then -- open list
        return "(", expr:sub(2)

    elseif ch == ")" or ch == "]" then -- close list
        return ")", expr:sub(2)

    -- Quoted lists are handled with (quote) form during evaluation step.
    elseif ch == "'" then
        return "'", expr:sub(2)

    -- There're no symbol data type in Lua, so both symbols
    -- and strings are represented as Lua strings.
    -- After I parse string I leave quote sign (") at its
    -- start, so I can distinguish them from symbols during
    -- evaluation step.
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

    -- short single-line comments
    elseif ch == ";" or expr:sub(1, 2) == "#!" then
        local s, e = expr:find("\n")
        if not s then return nil, "" end
        return token(expr:sub(e + 1))

    -- long multi-line comments
    elseif expr:sub(1, 2) == "#|" then
        local s, e = expr:find("|#")
        assert(s, "Syntax error: Missing long comment end")
        return token(expr:sub(e + 1))

    -- any other sequence of non-space characters is an identifier
    else
        t = expr:match("^[^][(%s)]+")
        if t then
            return t, expr:sub(1 + t:len())
        else
            return nil, expr -- parsing failed
        end
    end
end

-- Create iterator to tokenize given expression string
-- @see token()
local function tokenize(iter)
    local part
    if type(iter) == "string" then
        part = iter
        iter = function () end
    else
        part = iter()
    end

    local tokenize_part

    tokenize_part = function ()
        local t
        -- First we try to get token from current part
        t, part = token(part)

        if t then return t end

        -- If we can't get token from part we have now,
        -- then we should get next part and retry
        local next_part = iter()

        -- If we don't have next part, we are finished
        if not next_part then
            -- Raise error if we have some unparsed part
            if #part > 0 then error("Syntax error: Unparsed tail: '" .. part .. "'") end
            return
        end

        part = part .. next_part

        -- Tail recursion
        return tokenize_part()
    end

    return tokenize_part
end

local function parse(tokens)
    local t = tokens()
    if t == "#f" or t == "#F" then
        return false

    elseif t == "#t" or t == "#T" then
        return true

    --elseif t == "#<void>" or t == "#<undefined>" then
        --return nil

    elseif t == "(" then
        local result = {}
        for tt in parse, tokens do
            table.insert(result, tt)
        end

        return result

    elseif t == ")" or t == nil then
        return -- break loop on list or input end

    elseif t == "'" then
        return {"quote", parse(tokens)}

    else
        -- There're a lot of number formats in Scheme,
        -- I try to support most of them.
        local chch = t:sub(1, 2)
        local base = nil

        -- There're no exact and inexact numbers in Lua,
        -- all numbers are floats, so I just convert them
        -- into decimal number.
        if chch == "#i" or chch == "#e" then -- inexact and exact
            base = 10
        elseif chch == "#b" then -- binary
            base = 2
        elseif chch == "#o" then -- octal
            base = 8
        elseif chch == "#x" then -- hex
            base = 16
        end

        if base then t = t:sub(3) end

        -- If this is not a number literal, it should be a string
        -- (either literal string prefixed with quote (") or
        -- identitifier).
        return tonumber(t, base) or t
    end
end

-- Parse stream of tokens to convert them into evaluatable structure
-- It also parses literals, so literal string, number, boolean and nil
-- values are not evaluated dynamicly later.
--
-- @param string|iterator tokens
-- @return array of parsed tokens
local function compile(tokens)
    local result = {}

    tokens = tokenize(tokens)
    for form in parse, tokens do
        table.insert(result, form)
    end

    if #result < 2 then return result[1] end
    return { begin = result }
end
_M.string = compile

local function compilefile(file)
    return compile(io.lines(file))
end
_M.file = compilefile

return _M

