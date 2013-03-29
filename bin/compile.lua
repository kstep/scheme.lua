#!/usr/bin/lua

local scheme = require("scheme")
scheme.util = require("scheme.util")

local infile = arg[1]
local outfile = arg[2]

local code = scheme.compilefile(infile)

local result = ([[#!/usr/bin/lua
require("scheme").eval(]] .. scheme.util.lua_dump(code) .. [[)]])

if infile and not outfile then
    outfile = infile:gsub("[.]scm$", ".lscm")
end

io.output(outfile):write(result)
