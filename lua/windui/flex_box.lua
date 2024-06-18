local util = require("windui.util")
local clone = util.tbl.clone
local WindowState = require("windui.window_state")
---@alias windui.FlexBox.alignment "start"|"center"|"end"

---@class windui.FlexBox: windui.Layout
---@field windows windui.Component[]
---@field align windui.FlexBox.alignment
---@field vertical boolean
---@field main integer
local FlexBox = {
  class_name = "FlexBox",
}

---create new flex box layout
---@param windows windui.Component[]
---@param opts? { align?: windui.FlexBox.alignment, vertical?: boolean, main?: integer, state?: windui.WindowState }
---@return windui.FlexBox
function FlexBox.new(windows, opts)
  ---@type windui.FlexBox
  local o = {}
  setmetatable(o, {
    __index = FlexBox,
  })
  opts = vim.tbl_extend("force", {
    align = "center",
    vertical = false,
    main = 1,
    state = WindowState.new({
      width = vim.o.columns - 8,
      height = vim.o.lines - 8,
      border = "none",
    }):move_to("center"),
  }, opts or {})
  o.state = opts.state
  o.windows = windows
  o.opened = false
  o.align = opts.align
  o.vertical = opts.vertical
  o.main = opts.main
  return o
end

---update flex box layout state only and
---pass window and the update state for each window to {callback}
---@param state? windui.WindowState
---@param callback fun(window: windui.Component, winstate: windui.WindowState, index: integer)
function FlexBox:update_states(state, callback)
  if state then
    self.state = state
  end
  self.state.border = "none"

  local winstates = {}
  local heights = {}
  local widths = {}
  local width = 0
  local height = 0
  local curpos = 1
  for _, window in ipairs(self.windows) do
    if self.vertical then
    else
      local bordered = window.state:is_bordered()
      local w = window.state.width + (bordered.left and 1 or 0) + (bordered.right and 1 or 0)
      local h = window.state.height + (bordered.top and 1 or 0) + (bordered.bottom and 1 or 0)

      if w > self.state.width then
        if not widths[curpos] then
          widths[curpos] = { self.state.width }
          table.insert(heights, h)
        else
          table.insert(heights, height)
          widths[curpos + 1] = { self.state.width }
          table.insert(heights, h)
          curpos = curpos + 1
        end
        height = 0
        width = 0
        curpos = curpos + 1
      elseif w <= self.state.width - width then
        if h > height then
          height = h
        end
        width = width + window.state.width
        widths[curpos] = widths[curpos] or {}
        table.insert(widths[curpos], w)
      else
        table.insert(heights, height)
        width = w
        height = h
        curpos = curpos + 1
        widths[curpos] = { w }
      end
    end
  end
  if self.vertical and height ~= 0 then
    table.insert(heights, height)
  end

  local offsets = {}
  if self.vertical then
  else
    if self.align == "start" then
      for i = 1, #widths do
        offsets[i] = 0
      end
    else
      for i, w in ipairs(widths) do
        offsets[i] = 0
        for _, num in ipairs(w) do
          offsets[i] = offsets[i] + num
        end
        if self.align == "end" then
          offsets[i] = self.state.width - offsets[i]
        elseif self.align == "center" then
          offsets[i] = math.floor(self.state.width / 2) - math.floor(offsets[i] / 2)
        end
      end
    end
  end

  if self.vertical then
  else
    local i = 1
    local rowoff = 0
    ---@diagnostic disable-next-line: redefined-local
    for j, width in ipairs(widths) do
      local coloff = offsets[j]
      rowoff = rowoff + (heights[j - 1] or 0)
      for _, w in ipairs(width) do
        local window = self.windows[i]
        local winstate = clone(window.state)
        if winstate.height + rowoff > self.state.height then
          goto continue
        end
        winstate.relative = self.state.relative
        winstate.border = winstate.border or self.state.border
        winstate.blend = winstate.blend or self.state.blend
        winstate.row = self.state.row + rowoff
        winstate.col = self.state.col + coloff
        winstates[i] = winstate
        coloff = coloff + w
        i = i + 1
        ::continue::
      end
    end
  end

  for i, winstate in ipairs(winstates) do
    callback(self.windows[i], winstate, i)
  end
end

---open flex box layout if {enter} focus to main window
---@param enter? boolean
---@return self
function FlexBox:open(enter)
  if self.opened then return self end
  self.state.border = "none"
  if enter == nil then
    enter = false
  end

  self:update_states(nil, function(window, state, i)
    window.state = state
    window:open(enter and i == self.main)
  end)
  self.opened = true
  if self.after_open then
    self:after_open()
  end
  return self
end

---close flex box layout
---@param force? boolean
---@return self
function FlexBox:close(force)
  if force == nil then
    force = false
  end
  if not self.opened then return self end
  local function close()
    for _, window in ipairs(self.windows) do
      window:close(force)
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

---update flex box layout state
---@param state? windui.WindowState
---@return self
function FlexBox:update(state)
  self.state.border = "none"
  self:update_states(state, function(window, winstate)
    window:update(winstate)
  end)

  return self
end

---animate all UI component in stack layout
---@param time number
---@param fps integer
---@param state? windui.WindowState
---@param on_finish? function
---@return self
function FlexBox:animate(time, fps, state, on_finish)
  if not self.opened then return self end
  self.state.border = "none"
  self:update_states(state or self.state, function(window, winstate, i)
    window:animate(time, fps, window.state:clone(winstate), i == #self.windows and on_finish or nil)
  end)
  return self
end

---add keymapping to flex box layout
---@param mode string|string[]
---@param lhs string
---@param rhs function|string
---@return self
function FlexBox:map(mode, lhs, rhs)
  for _, window in ipairs(self.windows) do
    window:map(mode, lhs, rhs)
  end
  return self
end

---remove keymapping from flex box layout
---@param mode any
---@param lhs any
---@return self
function FlexBox:unmap(mode, lhs)
  for _, window in ipairs(self.windows) do
    window:unmap(mode, lhs)
  end
  return self
end

---add event handler for flex box layout
---@param event string|string[]
---@param pattern? string|string[]
---@param handler function|string
---@return self
function FlexBox:on(event, pattern, handler)
  for _, window in ipairs(self.windows) do
    window:on(event, pattern, handler)
  end
  return self
end

---remove event handler from flex box layout
---@param event string|string[]
---@param pattern? string|string[]
---@return self
function FlexBox:off(event, pattern)
  for _, window in ipairs(self.windows) do
    window:off(event, pattern)
  end
  return self
end

---play animation
---@param anim windui.Animation
---@param on_finish? function
---@return self
function FlexBox:play(anim, on_finish)
  if not self.opened then return self end
  anim:play(self, on_finish)
  return self
end

---focus to the main window
---@return self
function FlexBox:focus()
  if not self.opened then return self end
  local win = self.windows[self.main]
  if not win then return self end
  win:focus()
  return self
end

return FlexBox
