#!/usr/bin/lua

package.path = package.path .. ";./?/init.lua"

local scheme = require("scheme")
scheme.util = require("scheme.util")

local code = scheme.compilefile(arg[1])

print([[#!/usr/bin/lua
package.path = package.path .. ";./?/init.lua"
local scheme = require("scheme")
scheme.eval(]] .. scheme.util.lua_dump(code) .. [[)]])

