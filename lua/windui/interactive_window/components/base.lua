---@class windui.IWComponent
---@field class_name string
---@field row integer
---@field col integer
---@field width integer
---@field height integer
---@field padding windui.padding
---@field margin windui.margin
---@field parent windui.IWComponent?
local Base = {
  class_name = "IWComponent.Base",
}

---create new component for windui.InteractiveWindow
function Base.new()
  local o = {}
  setmetatable(o, { __index = Base })
  return o
end

---draw the component to {win} on position {pos}
---@param win windui.InteractiveWindow
---@param pos [integer, integer]
function Base:draw(win, pos)
  vim.notify("method not implemented", vim.log.levels.ERROR)
end

setmetatable(Base, {
  __call = function(t, ...)
    return t.new(...)
  end
})

return Base
