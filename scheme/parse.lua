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
    elseif expr:sub(1, 2) == "'(" then
        return token("(quote " .. expr:sub(3))

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
local function tokenize(expr)
    local state = expr
    return function ()
        local t
        t, state = token(state)
        return t
    end
end
_M.tokenize = tokenize

-- Parse stream of tokens to convert them into evaluatable structure
-- It also parses literals, so literal string, number, boolean and nil
-- values are not evaluated dynamicly later.
--
-- @param string|iterator tokens
-- @return array of parsed tokens
local function parse(tokens)
    local result = {}
    if type(tokens) == "string" then
        tokens = tokenize(tokens)
    end

    for t in tokens do
        if t == "(" then -- table starts
            table.insert(result, parse(tokens))

        elseif t == ")" then -- table ends
            if type(result) ~= "table" then
                error("Syntax error: Unbalanced parenthesis")
            end
            return result

	-- booleans
        elseif t == "#f" or t == "#F" then
            table.insert(result, false)

        elseif t == "#t" or t == "#T" then
            table.insert(result, true)

	-- We don't support infix dot operator, as there're no
	-- real cons cells in Lua, hence (a . b) and (a b)
	-- are represented in the same way in Lua land
	-- (as an table array: {a, b}).
        elseif t == "." then
            -- skip
    
	-- Special "void" constants map to Lua's nil
        elseif t == "#<void>" or t == "#<undefined>" then
            table.insert(result, nil)

	-- Otherwise we have a string.
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

