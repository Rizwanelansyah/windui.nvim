local WindowState = require("windui.window_state")
local util        = require("windui.util")

---@class windui.Stack: windui.UIComponent
---@field class_name string
---@field vertical boolean
---@field windows ({ size: number, child: windui.UIComponent })[]
---@field state windui.WindowState
---@field spacing integer
---@field main integer
---@field opened boolean
local Stack       = {
  class_name = "Stack",
}

---create stack layout
---@param windows (windui.UIComponent|{ size: number, child: windui.UIComponent })[]
---@param opts? { main?: integer, state?: windui.WindowState, vertical?: boolean, spacing?: integer }
---@return windui.Stack
function Stack.new(windows, opts)
  opts = vim.tbl_extend('force', {
    vertical = false,
    main = 0,
    state = WindowState.new({
      width = vim.o.columns - 8,
      height = vim.o.lines - 8,
      border = "none",
    }):move_to("center"),
    spacing = 0,
  }, opts or {})
  ---@type windui.Stack
  local o = {}
  for key, val in pairs(opts or {}) do
    o[key] = val
  end

  o.state = opts.state
  o.vertical = opts.vertical
  o.main = opts.main
  o.spacing = opts.spacing
  o.opened = false
  setmetatable(o, {
    __index = Stack,
  })
  o.windows = vim.tbl_map(function(value)
    if not value.child then
      return { size = 0, child = value }
    end
    return value
  end, windows)
  return o
end

---open stack layout if {enter} focus to main window
---@param enter? boolean
---@return windui.Stack
function Stack:open(enter)
  if self.opened then return self end
  self.state.border = "none"
  if enter == nil then
    enter = false
  end

  self:update_states(nil, function(window, state, i)
    window.child.state = state
    window.child:open(i == self.main)
  end)
  self.opened = true
  return self
end

---close stack layout
---@param force boolean
---@return windui.Stack
function Stack:close(force)
  if not self.opened then return self end
  self.state.border = "none"
  for _, window in ipairs(self.windows) do
    window.child:close(force)
  end

  self.opened = false
  return self
end

---update stack layout state only and
---and pass window and the update state for each window
---@param state? windui.WindowState
---@param callback fun(window: { size: integer, child: windui.UIComponent }, winstate: windui.WindowState, index: integer)
function Stack:update_states(state, callback)
  if state then
    self.state = state
  end

  local max = self.state.width or 0
  local same_size = 0
  if self.vertical then
    max = self.state.height or 0
  end
  local remain = max

  for _, window in ipairs(self.windows) do
    if window.size == 0 then
      same_size = same_size + 1
    elseif window.size >= 1 then
      remain = remain - window.size
    else
      remain = remain - math.floor(max * window.size)
    end
  end

  local sizes = {}
  local same_sizes = util.math.div_list_int(math.floor(remain), same_size)
  local j = 1
  for i, window in ipairs(self.windows) do
    if window.size == 0 then
      sizes[i] = same_sizes[j]
      j = j + 1
    elseif window.size >= 1 then
      sizes[i] = window.size
    else
      sizes[i] = window.size * max
    end
  end

  local offset = 0
  local winstates = {}
  local len = #self.windows
  for i, window in ipairs(self.windows) do
    local winstate = self.state:clone {}
    winstate.border = window.child.state.border
    local borderred = winstate.border ~= "none"
    local addition = (borderred and 2 or 0)
    if self.vertical then
      winstate.height = sizes[i] - addition - (i ~= len and self.spacing or 0)
      winstate.width = self.state.width - addition
      winstate.row = winstate.row + offset
    else
      winstate.width = sizes[i] - addition - (i ~= len and self.spacing or 0)
      winstate.height = self.state.height - addition
      winstate.col = winstate.col + offset
    end
    if winstate.height < 1 then
      winstate.height = self.state.height - (self.state.height < 3 and 0 or addition)
      winstate.row = self.state.row
    end
    if winstate.width < 1 then
      winstate.width = self.state.width - (self.state.width < 3 and 0 or addition)
      winstate.col = self.state.col
    end
    winstates[i] = winstate
    offset = offset + sizes[i]
  end
  for i, winstate in ipairs(winstates) do
    callback(self.windows[i], winstate, i)
  end
end

---update stack layout state
---@param state? windui.WindowState
---@return windui.Stack
function Stack:update(state)
  self.state.border = "none"
  self:update_states(state, function(window, winstate)
    window.child:update(winstate)
  end)

  return self
end

---animate all UI component in stack layout
---@param time number
---@param fps integer
---@param state? windui.WindowState
---@param on_finish? function
---@return windui.Stack
function Stack:animate(time, fps, state, on_finish)
  if not self.opened then return self end
  self.state.border = "none"
  self:update_states(state or self.state, function(window, winstate, i)
    window.child:animate(time, fps, window.child.state:clone(winstate), i == #self.windows and on_finish or nil)
  end)
  return self
end

---add keymapping to stack layout
---@param mode string|string[]
---@param lhs string
---@param rhs function|string
---@return windui.Stack
function Stack:map(mode, lhs, rhs)
  for _, window in ipairs(self.windows) do
    window.child:map(mode, lhs, rhs)
  end
  return self
end

---remove keymapping from stack layout
---@param mode any
---@param lhs any
---@return windui.Stack
function Stack:unmap(mode, lhs)
  for _, window in ipairs(self.windows) do
    window.child:unmap(mode, lhs)
  end
  return self
end

---add event handler for stack layout
---@param event string|string[]
---@param pattern? string|string[]
---@param handler function|string
---@return windui.Stack
function Stack:on(event, pattern, handler)
  for _, window in ipairs(self.windows) do
    window.child:on(event, pattern, handler)
  end
  return self
end

---remove event handler from stack layout
---@param event string|string[]
---@param pattern? string|string[]
---@return windui.Stack
function Stack:off(event, pattern)
  for _, window in ipairs(self.windows) do
    window.child:off(event, pattern)
  end
  return self
end

---play animation
---@param anim windui.Animation
---@param on_finish? function
---@return windui.Stack
function Stack:play(anim, on_finish)
  if not self.opened then return self end
  anim:play(self, on_finish)
  return self
end

---focus to the main window
---@return windui.Stack
function Stack:focus()
  if not self.opened then return self end
  local win = self.windows[self.main].child
  if not win then return self end
  win:focus()
  return self
end

return Stack
