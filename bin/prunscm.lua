#!/usr/bin/lua5.1

require("profiler")
profiler.start("profiler.log")

local scheme = require("scheme")
for _, a in ipairs(arg) do
    if a ~= "!#" then
        scheme.runfile(a)
        break
    end
end

profiler.stop()
