local util = require("windui.util")
local Label = require("windui.interactive_window.components.label")

---@class windui.IWComponent.Button : windui.IWComponent.Label
local Button = {
  class_name = "IWComponent.Button",
}

setmetatable(Button, {
  __index = Label,
  __call = function(t, ...)
    return t.new(...)
  end
})

---@class windui.IWComponent.Button.opts : windui.IWComponent.Label.opts

---create new button component
---@param opt windui.IWComponent.Button.opts
---@return windui.IWComponent.Button
function Button.new(opt)
  opt.width = opt.width or 10
  if opt.width < 3 then
    opt.width = 3
  end
  opt.height = opt.height or 3
  if opt.height < 3 then
    opt.height = 3
  end
  local o = Label.new(opt) --[[@as windui.IWComponent.Button]]
  setmetatable(o, { __index = Button })
  return o
end

---draw the component to {win} on position {pos}
---@param win windui.InteractiveWindow
---@param pos [integer, integer]?
function Button:draw(win, pos)
end

return Button
