#!/usr/bin/lua

package.path = package.path .. ";./?/init.lua"

local scheme = require("scheme")
scheme.runfile(arg[1])
