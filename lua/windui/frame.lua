local Window = require("windui.window")
local util = require("windui.util")

---@class windui.Frame: windui.Window
---@field child windui.Component
---@field private _update fun(self: self, state?: windui.WindowState): self
local Frame = {
  class_name = "Frame",
}

setmetatable(Frame, { __index = Window })

---create new frame window
---@param config vim.api.keyset.win_config
---@param child windui.Component
---@return windui.Frame
function Frame.new(config, child)
  ---@type windui.Frame
  local o = Window.new(config) --[[@as windui.Frame]]
  setmetatable(o, { __index = Frame })
  o.child = child
  o.child:on('WinClosed', nil, function()
    o:close(true)
  end, "WindUIFrame")
  return o
end

---open frame
---@param enter boolean
---@return windui.Frame
function Frame:open(enter)
  if self.win then return self end
  self:_update()
  Window.open(self, false)
  local zindex = self.win and vim.api.nvim_win_get_config(self.win).zindex or (self.window.zindex or 1)
  self.child.state.zindex = zindex + 1
  self.child:open(enter)
  return self
end

---update frame
---@param state windui.WindowState
---@return windui.Frame
function Frame:_update(state)
  if state then
    self.state = state
  end
  local bordered = self.state:is_bordered()
  local cbordered = self.child.state:is_bordered()
  self.child.state.row = self.state.row + (bordered.top and 1 or 0)
  self.child.state.col = self.state.col + (bordered.left and 1 or 0)
  self.child.state.height = self.state.height
  self.child.state.width = self.state.width

  if util.tbl.instance_of(self.child, Window.class_name) then
    self.child.state.height = self.child.state.height - (cbordered.top and 1 or 0) - (cbordered.bottom and 1 or 0)
    self.child.state.width = self.child.state.width - (cbordered.left and 1 or 0) - (cbordered.right and 1 or 0)
  end

  local zindex = self.win and vim.api.nvim_win_get_config(self.win).zindex or (self.state.zindex or 1)
  self.child.state.zindex = zindex + 1
  return self
end

---close frame
---@param force boolean
---@return windui.Frame
function Frame:close(force)
  if not self.win then return self end
  self.child:close(force)
  Window.close(self, force)
  return self
end

---update frame
---@param state windui.WindowState
---@return windui.Frame
function Frame:update(state)
  self:_update(state)
  Window.update(self)
  local zindex = self.win and vim.api.nvim_win_get_config(self.win).zindex or (self.state.zindex or 1)
  self.child.state.zindex = zindex + 1
  self.child:update()
  return self
end

---focus to the child
---@return windui.Frame
function Frame:focus()
  self.child:focus()
  return self
end

---add mapping to child
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@return windui.Frame
function Frame:map(mode, lhs, rhs)
  self.child:map(mode, lhs, rhs)
  return self
end

---remove mapping from child
---@param mode string|string[]
---@param lhs string
---@return windui.Frame
function Frame:unmap(mode, lhs)
  self.child:unmap(mode, lhs)
  return self
end

-- local Stack = require("windui.stack")
-- local s = Stack.new {
--   Window.new {},
--   Window.new {},
-- }
-- local f = Frame.new({
--   width = 20,
--   height = 5,
--   border = "double",
-- }, s)
-- f.state = f.state:move_to("center")
-- f:map('n', '<esc>', function()
--   f:close(true)
-- end)
-- f:open(true)
-- f:animate(0.3, 120, f.state:clone({
--   width = 50,
--   height = 40,
-- }):move_to("center"), function()
--   s.vertical = true
--   s:animate(0.3, 120, s.state)
-- end)

return Frame
