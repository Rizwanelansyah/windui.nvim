local WindowState = require("windui.window_state")
local util        = require("windui.util")
local Layout      = require("windui.layout")
local class       = require("classic.class")

---@class windui.Stack.opts
---@field main? integer
---@field state? windui.WindowState
---@field vertical? boolean
---@field spacing? integer

---@class windui.Stack: windui.Layout
---@field vertical boolean
---@field windows ({ size: number, child: windui.Component })[]
---@field state windui.WindowState
---@field spacing integer
---@field main integer
---
---@field new fun(windows: (windui.Component|{ size: number, child: windui.Component })[], opts?: windui.Stack.opts ): windui.Stack
local Stack       = {}
class(Stack, Layout, function(C)
  C.public()
  Stack.vertical = false
  Stack.windows = nil
  Stack.state = nil
  Stack.spacing = 0
  Stack.main = nil

  ---create stack layout
  ---@param windows (windui.Component|{ size: number, child: windui.Component })[]
  ---@param opts? { main?: integer, state?: windui.WindowState, vertical?: boolean, spacing?: integer }
  function Stack:__init(windows, opts)
    opts = vim.tbl_extend('force', {
      vertical = false,
      main = 1,
      state = WindowState.new({
        width = vim.o.columns - 8,
        height = vim.o.lines - 8,
        border = "none",
      }):move_to("center"),
      spacing = 0,
    }, opts or {})
    ---@type windui.Stack
    for key, val in pairs(opts or {}) do
      self[key] = val
    end

    self.state = opts.state
    self.state.border = "none"
    self.vertical = opts.vertical
    self.main = opts.main
    self.spacing = opts.spacing
    self.opened = false
    self.windows = vim.tbl_map(function(value)
      if not value.child then
        return { size = 0, child = value }
      end
      return value
    end, windows)
  end

  ---open stack layout if {enter} focus to main window
  ---@param enter? boolean
  ---@return self
  function Stack:open(enter)
    if self.opened then return self end
    self.state.border = "none"
    if enter == nil then
      enter = false
    end

    self:update_states(nil, function(window, state, i)
      window.child.state = state
      window.child:open(enter and i == self.main)
    end)
    self.opened = true
    if self.after_open then
      self:after_open()
    end
    return self
  end

  ---close stack layout
  ---@param force boolean
  ---@return self
  function Stack:close(force)
    if not self.opened then return self end
    local function close()
      for _, window in ipairs(self.windows) do
        window.child:close(force)
      end

      self.opened = false
    end
    if self.before_close then
      self:before_close(close)
    else
      close()
    end
    return self
  end

  ---update stack layout state only and
  ---pass window and the update state for each window to {callback}
  ---@param state? windui.WindowState
  ---@param callback fun(window: { size: integer, child: windui.Component }, winstate: windui.WindowState, index: integer)
  function Stack:update_states(state, callback)
    if state then
      self.state = state
    end
    self.state.border = "none"

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
      winstate.border = window.child.state.border or self.state.border
      winstate.blend = window.child.state.blend or self.state.blend
      local borderred = winstate:is_bordered()
      local vert_add = (borderred.top and 1 or 0) + (borderred.bottom and 1 or 0)
      local horiz_add = (borderred.left and 1 or 0) + (borderred.right and 1 or 0)
      if self.vertical then
        winstate.height = sizes[i] - vert_add - (i ~= len and self.spacing or 0)
        winstate.width = self.state.width - horiz_add
        winstate.row = winstate.row + offset
      else
        winstate.width = sizes[i] - horiz_add - (i ~= len and self.spacing or 0)
        winstate.height = self.state.height - vert_add
        winstate.col = winstate.col + offset
      end
      if winstate.height < 1 then
        winstate.height = self.state.height - (self.state.height < 3 and 0 or horiz_add)
        winstate.row = self.state.row
      end
      if winstate.width < 1 then
        winstate.width = self.state.width - (self.state.width < 3 and 0 or vert_add)
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
  ---@return self
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
  ---@return self
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
  ---@return self
  function Stack:map(mode, lhs, rhs)
    for _, window in ipairs(self.windows) do
      window.child:map(mode, lhs, rhs)
    end
    return self
  end

  ---remove keymapping from stack layout
  ---@param mode any
  ---@param lhs any
  ---@return self
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
  ---@return self
  function Stack:on(event, pattern, handler)
    for _, window in ipairs(self.windows) do
      window.child:on(event, pattern, handler)
    end
    return self
  end

  ---remove event handler from stack layout
  ---@param event string|string[]
  ---@param pattern? string|string[]
  ---@return self
  function Stack:off(event, pattern)
    for _, window in ipairs(self.windows) do
      window.child:off(event, pattern)
    end
    return self
  end

  ---play animation
  ---@param anim windui.Animation
  ---@param on_finish? function
  ---@return self
  function Stack:play(anim, on_finish)
    if not self.opened then return self end
    anim:play(self, on_finish)
    return self
  end

  ---focus to the main window
  ---@return self
  function Stack:focus()
    if not self.opened then return self end
    local win = self.windows[self.main].child
    if not win then return self end
    win:focus()
    return self
  end
end)

return Stack
