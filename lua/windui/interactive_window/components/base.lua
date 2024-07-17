---@class windui.IWComponent
---@field class_name string
---@field row integer
---@field col integer
---@field width integer
---@field height integer
---@field padding windui.padding
---@field margin windui.margin
---@field parent windui.IWComponent?
---@field on_focus? fun(self: self)
---@field on_lost_focus? fun(self: self)
---@field on_hold? fun(self: self)
---@field drawed boolean
local Base = {
  class_name = "IWComponent.Base",
  drawed = false,
}

---@enum (key) windui.IWComponent.Event
local Event = {
  focus = 1,
  lost_focus = 2,
  hold = 3,
}

---create new component for windui.InteractiveWindow
function Base.new()
  local o = {}
  setmetatable(o, { __index = Base })
  return o
end

---draw the component to {win} on position {pos}
---@param win windui.InteractiveWindow
---@param pos? [integer, integer]
function Base:draw(win, pos)
  vim.notify("method not implemented", vim.log.levels.ERROR)
end

---add event handler to IWComponent
---@param event windui.IWComponent.Event
---@param fun fun(self: self)
---@return windui.IWComponent
function Base:on(event, fun)
  self["on_"..event] = fun
  return self
end

---get the hit box of the component
---@return { top: integer, left: integer, right: integer, bottom: integer }
function Base:get_hit_box()
  return {
    top = self.row + 1,
    left = self.col,
    right = self.col + self.width - 1,
    bottom = self.row + self.height,
  }
end

setmetatable(Base, {
  __call = function(t, ...)
    return t.new(...)
  end
})

return Base
