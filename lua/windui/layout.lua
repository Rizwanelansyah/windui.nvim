local class = require("classic.class")

---@class windui.Layout: windui.Component
---@field opened boolean
local Layout = {}
class(Layout, function (C)
  C.public()
  Layout.opened = false
end)

return Layout
