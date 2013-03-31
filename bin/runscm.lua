#!/usr/bin/lua

local scheme = require("scheme")
for _, a in ipairs(arg) do
    if a ~= "!#" then
        scheme.runfile(a)
        break
    end
end
