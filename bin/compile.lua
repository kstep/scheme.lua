#!/usr/bin/lua

local scheme = require("scheme")
scheme.util = require("scheme.util")

local code = scheme.compilefile(arg[1])

print([[#!/usr/bin/lua
require("scheme").eval(]] .. scheme.util.lua_dump(code) .. [[)]])

