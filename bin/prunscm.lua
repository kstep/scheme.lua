#!/usr/bin/lua5.1

require("profiler")
profiler.start("profiler.log")

local scheme = require("scheme")
scheme.runfile(arg[1])

profiler.stop()
