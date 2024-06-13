local AnimationFrame = require("windui.animation_frame")
-- local util = require("windui.util")
---@class windui.Window.OpenOpts

---@class windui.Window
---@field private _window vim.api.keyset.win_config
---@field private _mappings table<string, table<string, string|function>>
---@field private _events table<string, vim.api.keyset.create_autocmd[]>
---@field anim_frame windui.AnimationFrame
---@field win integer?
---@field buf integer?
local Window = {
  _window = {
    col = 0,
    row = 0,
    height = 8,
    relative = "editor",
    border = "single",
    style = "minimal",
    width = 20,
    hide = false,
    focusable = true,
  },
  _mappings = {},
  _events = {},
  anim_frame = AnimationFrame.new(),
}

---create a new Window
---@param config? vim.api.keyset.win_config
---@return windui.Window
function Window.new(config)
  local t = {}
  setmetatable(t, {
    __index = Window,
  })
  if config then
    t._window = vim.tbl_extend('force', t._window, config)
  end
  t.anim_frame = AnimationFrame.new(t._window)
  return t
end

---open the Window
---@param enter? boolean
---@param opts? windui.Window.OpenOpts
---@return windui.Window
function Window:open(enter, opts)
  if enter == nil then enter = false end
  opts = vim.tbl_extend("force", {}, opts or {})
  if self.win or self.buf then return self end
  self.buf = vim.api.nvim_create_buf(false, true)

  for mode, mapping in pairs(self._mappings) do
    for lhs, rhs in pairs(mapping) do
      vim.api.nvim_buf_set_keymap(
        self.buf,
        mode,
        lhs,
        type(rhs) == "string" and rhs or "",
        type(rhs) == "function" and {
          callback = rhs
        } or {}
      )
    end
  end

  vim.api.nvim_create_augroup("WindUI", {})
  for event, events in pairs(self._events) do
    for _, opt in ipairs(events) do
      vim.api.nvim_create_autocmd(event, {
        group = "WindUI",
        buffer = self.buf,
        pattern = opt.pattern,
        callback = opt.callback,
        command = opt.command,
      })
    end
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = self.buf,
    group = "WindUI",
    callback = function()
      self.win = nil
      self.buf = nil
    end
  })

  self.win = vim.api.nvim_open_win(self.buf, enter, self._window)
  return self
end

---close the window
---@param force? boolean
---@return windui.Window
function Window:close(force)
  if force == nil then
    force = true
  end
  if self.win then
    vim.api.nvim_win_close(self.win --[[@as integer]], force)
    self.win = nil
  end
  if self.buf then
    for mode, mapping in pairs(self._mappings) do
      for lhs, _ in pairs(mapping) do
        vim.api.nvim_buf_del_keymap(self.buf, mode, lhs)
      end
    end
    vim.api.nvim_clear_autocmds { group = "WindUI", buffer = self.buf }
    vim.api.nvim_buf_delete(self.buf --[[@as integer]], { force = force })
    self.buf = nil
  end
  return self
end

---add mapping to window
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@return windui.Window
function Window:map(mode, lhs, rhs)
  local modes = type(mode) == "string" and { mode } or mode --[[@as table]]
  for _, m in ipairs(modes) do
    if not self._mappings[m] then
      self._mappings[m] = {}
    end
    self._mappings[m][lhs] = rhs
  end
  if self.win and self.buf then
    vim.keymap.set(mode, lhs, rhs, { buffer = self.buf })
  end
  return self
end

---delete mapping from window
---@param mode string|string[]
---@param lhs string
---@return windui.Window
function Window:unmap(mode, lhs)
  local modes = type(mode) == "string" and { mode } or mode --[[@as table]]
  for _, m in ipairs(modes) do
    if not self._mappings[m] then
      self._mappings[m] = {}
    end
    self._mappings[m][lhs] = nil
  end
  if self.win and self.buf then
    vim.keymap.del(mode, lhs, { buffer = self.buf })
  end
  return self
end

---update the animation frame and config
---@param anim_frame? windui.AnimationFrame
---@return windui.Window
function Window:update(anim_frame)
  if not self.win then return self end
  if anim_frame then
    self.anim_frame = anim_frame
  end
  self._window = vim.tbl_extend('force', self._window, self.anim_frame)
  local config = vim.tbl_extend('force', self._window, self.anim_frame:map {
    width = math.floor,
    height = math.floor,
  })
  vim.api.nvim_win_set_config(self.win, config)
  return self
end

---animate window
---@param time integer
---@param fps integer
---@param end_ windui.AnimationFrame
---@param on_finish? function
function Window:animate(time, fps, end_, on_finish)
  local begin = self.anim_frame

  local row_range = begin.row > end_.row and begin.row - end_.row or end_.row - begin.row
  local col_range = begin.col > end_.col and begin.col - end_.col or end_.col - begin.col
  local width_range = begin.width > end_.width and begin.width - end_.width or end_.width - begin.width
  local height_range = begin.height > end_.height and begin.height - end_.height or end_.height - begin.height

  local row_speed = row_range / (time * fps)
  local col_speed = col_range / (time * fps)
  local width_speed = width_range / (time * fps)
  local height_speed = height_range / (time * fps)

  if begin.row > end_.row then row_speed = row_speed * -1 end
  if begin.col > end_.col then col_speed = col_speed * -1 end
  if begin.width > end_.width then width_speed = width_speed * -1 end
  if begin.height > end_.height then height_speed = height_speed * -1 end

  local frame = 0
  local end_frame = time * fps
  local timer = vim.uv.new_timer()
  local delay = (time / (time * fps)) * 1000
  local function animate()
    self.anim_frame = self.anim_frame:add {
      row = row_speed,
      col = col_speed,
      width = width_speed,
      height = height_speed,
    }
    self:update()
    frame = frame + 1
    if frame == end_frame then
      self.anim_frame = end_
      self:update()
      if on_finish then
        on_finish()
      end
    else
      timer:start(delay, 0, vim.schedule_wrap(animate))
    end
  end
  animate()
end

---add {handler} to {event} with {pattern}
---@param event string
---@param pattern? string|string[]
---@param handler function|string
function Window:on(event, pattern, handler)
  local event_opts = {
    pattern = pattern,
    group = "WindUI",
    buffer = self.buf,
    callback = type(handler) == "function" and handler or nil,
    command = type(handler) == "string" and handler or nil,
  }
  if not self._events[event] then
    self._events[event] = {}
  end
  table.insert(self._events[event], {
    pattern = pattern,
    callback = event_opts.callback,
    command = event_opts.command,
  })

  if not self.win then return end
  vim.api.nvim_create_augroup("WindUI", {})
  vim.api.nvim_create_autocmd(event, event_opts)
end

---remove {event} handler with {pattern}
---@param event string
---@param pattern? string|string[]
function Window:off(event, pattern)
  if self._events[event] then
    self._events[event] = vim.tbl_filter(function(val)
      if val.pattern then
        return not (pattern and val.pattern == pattern)
      else
        return false
      end
    end, self._events[event])
  end

  if not self.win then return end
  vim.api.nvim_clear_autocmds({
    event = event,
    pattern = pattern,
    buffer = self.buf,
    group = "WindUI",
  })
end

return Window
