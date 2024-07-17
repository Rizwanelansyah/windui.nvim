local Window = require("windui.window")
local util = require("windui.util")

---@class windui.InteractiveWindow : windui.Window
---@field content windui.IWComponent[]
---@field last_pos [integer, integer]
local InteractiveWindow = {
  class_name = "InteractiveWindow",
}

setmetatable(InteractiveWindow, { __index = Window })

---create new interactive window
---@param config vim.api.keyset.win_config
---@param content windui.IWComponent[]?
---@return windui.InteractiveWindow
function InteractiveWindow.new(config, content)
  local o = Window.new(config) --[[@as windui.InteractiveWindow]]
  setmetatable(o, { __index = InteractiveWindow })
  o.content = content or {}
  o.last_pos = { 0, 0 }

  o:on("CursorMoved", nil, function()
    local pos = vim.api.nvim_win_get_cursor(o.win)
    local last_focus = o:get_component_at(o.last_pos)
    local focused = o:get_component_at(pos)
    if last_focus ~= focused or (not last_focus and focused) then
      if last_focus and last_focus.on_lost_focus then
        o:unlock()
        last_focus:on_lost_focus()
        last_focus:draw(o)
        o:lock()
      end
      if focused and focused.on_focus then
        o:unlock()
        focused:on_focus()
        focused:draw(o)
        o:lock()
      end
    end
    o.last_pos = pos
  end, "InteractiveWindow")

  o:on("CursorHold", nil, function()
    local pos = vim.api.nvim_win_get_cursor(o.win)
    local focused = o:get_component_at(pos)
    if focused and focused.on_hold then
      o:unlock()
      focused:on_hold()
      focused:draw(o)
      o:lock()
    end
  end, "InteractiveWindow")
  return o
end

---get component at {pos}
---@param pos [integer, integer]
---@return windui.IWComponent?
function InteractiveWindow:get_component_at(pos)
  for _, comp in ipairs(self.content) do
    local hit_box = comp:get_hit_box()
    if pos[1] >= hit_box.top
        and pos[2] >= hit_box.left
        and pos[1] <= hit_box.bottom
        and pos[2] <= hit_box.right
    then
      return comp
    end
  end
end

---open window
---@param enter boolean?
function InteractiveWindow:open(enter)
  Window.open(self, enter)
  if not self.win then return end
  self:unlock()
  for i = 1, self.state.height do
    vim.api.nvim_buf_set_lines(self.buf, i - 1, i, false, { string.rep(" ", self.state.width) })
  end
  local i = 0
  local parent = {
    height = self.state.height,
    width = self.state.width,
    row = 0,
    col = 0,
    padding = util.ui.spacing(0),
  } --[[@as windui.IWComponent ]]
  for _, comp in ipairs(self.content) do
    comp.parent = parent
    comp:draw(self, { comp.margin.top + i, comp.margin.left + 0 })
    i = i + comp.height + comp.margin.top + comp.margin.bottom
  end
  self:lock()
end

---set the window to modifiable
function InteractiveWindow:unlock()
  if not self.win then return end
  vim.bo[self.buf].readonly = false
  vim.bo[self.buf].modifiable = true
end

---set the window to readonly
function InteractiveWindow:lock()
  if not self.win then return end
  vim.bo[self.buf].readonly = true
  vim.bo[self.buf].modifiable = false
end

return InteractiveWindow
