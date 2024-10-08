local class = require("classic.class")
local WindowComponent = require("windui.window_component")
local WindowState = require("windui.window_state")

---@class windui.Window: windui.Component
---@field protected _mappings table<string, table<string, string|function>>
---@field protected _events table<string, vim.api.keyset.create_autocmd[]>
---
---@field window vim.api.keyset.win_config
---@field state windui.WindowState
---@field win integer?
---@field buf integer?
---@field opt { buf: table, win: table }
---
---create a new Window
---@field new fun(config?: vim.api.keyset.win_config): windui.Window
local Window = {}
class(Window, WindowComponent, function(C)
  Window._mappings = nil
  Window._events = nil

  C.public()
  Window.window = nil
  Window.state = nil
  Window.win = nil
  Window.buf = nil
  Window.opt = nil

  function Window:__init(config)
    self._mappings = {}
    self._events = {}
    self.opt = { win = {}, buf = {} }
    self.window = vim.tbl_extend('force', {
      col = 0,
      row = 0,
      height = 1,
      relative = "editor",
      border = "single",
      style = "minimal",
      width = 1,
      hide = false,
      focusable = true,
    }, config or {})
    self.state = WindowState.new(self.window)
  end

  ---open the Window
  ---@param enter? boolean
  ---@return windui.Window
  function Window:open(enter)
    if enter == nil then enter = false end
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

    vim.api.nvim_create_augroup("WindUI", { clear = false })
    for event, events in pairs(self._events) do
      for _, opt in ipairs(events) do
        local group = opt.group
        if type(group) == "string" then
          group = vim.api.nvim_create_augroup(group, { clear = false })
        end
        vim.api.nvim_create_autocmd(event, {
          group = group,
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

    local config = vim.tbl_extend('force', self.window, self.state)
    config.blend = nil
    self.win = vim.api.nvim_open_win(self.buf, enter, config)
    for wo, value in pairs(self.opt.win) do
      vim.wo[self.win][wo] = value
    end
    for bo, value in pairs(self.opt.buf) do
      vim.bo[self.buf][bo] = value
    end
    vim.wo[self.win].winblend = math.floor(self.state.blend or 0)

    if self.after_open then
      self:after_open()
    end
    return self
  end

  ---close the window
  ---@param force? boolean
  ---@return windui.Window
  function Window:close(force)
    if force == nil then
      force = true
    end
    local function close_win()
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
        for event, opts in pairs(self._events) do
          for _, opt in ipairs(opts) do
            vim.api.nvim_clear_autocmds { event = event, buffer = self.buf, group = opt.group, pattern = opt.pattern }
          end
        end
        vim.api.nvim_buf_delete(self.buf, { force = force })
        self.buf = nil
      end
    end
    if self.before_close then
      self:before_close(close_win)
    else
      close_win()
    end
    return self
  end

  ---add mapping to window
  ---@param mode string|string[]
  ---@param lhs string
  ---@param rhs string|fun(self: windui.Window)
  ---@return windui.Window
  function Window:map(mode, lhs, rhs)
    local modes = type(mode) == "string" and { mode } or mode --[[@as table]]
    if type(rhs) == "function" then
      local inner = rhs
      rhs = function()
        inner(self)
      end
    end
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

  ---update the state and config
  ---@param state? windui.WindowState
  ---@return windui.Window
  function Window:update(state)
    if state then
      self.state = state
    end
    self.window = vim.tbl_extend('force', self.window, self.state)
    ---@diagnostic disable-next-line: inject-field
    self.window.blend = nil
    if not self.win then
      self:open(false)
    end
    local function floor_or(alt)
      return function(num)
        if not num then return end
        local result = math.floor(num)
        return result <= 0 and alt or result
      end
    end
    local config = vim.tbl_extend('force', self.window, self.state:map {
      width = floor_or(1),
      height = floor_or(1),
      row = floor_or(0),
      col = floor_or(0),
    })
    config.blend = nil
    vim.api.nvim_win_set_config(self.win, config)
    for wo, value in pairs(self.opt.win) do
      vim.wo[self.win][wo] = value
    end
    for bo, value in pairs(self.opt.buf) do
      vim.bo[self.buf][bo] = value
    end
    vim.print(math.floor(self.state.blend or 0))
    vim.wo[self.win].winblend = math.floor(self.state.blend or 0)
    return self
  end

  ---animate window
  ---@param time integer
  ---@param fps integer
  ---@param _end windui.WindowState
  ---@param on_finish? function
  ---@return windui.Window
  function Window:animate(time, fps, _end, on_finish)
    local begin = self.state

    local row_range
    if begin.row or _end.row then
      begin.row = begin.row or 0
      _end.row = _end.row or 0
      row_range = begin.row > _end.row and begin.row - _end.row or _end.row - begin.row
    end

    local col_range
    if begin.col or _end.col then
      begin.col = begin.col or 0
      _end.col = _end.col or 0
      col_range = begin.col > _end.col and begin.col - _end.col or _end.col - begin.col
    end

    local width_range
    if begin.width or _end.width then
      begin.width = begin.width or 1
      _end.width = _end.width or 1
      width_range = begin.width > _end.width and begin.width - _end.width or _end.width - begin.width
    end

    local height_range
    if begin.height or _end.height then
      begin.height = begin.height or 1
      _end.height = _end.height or 1
      height_range = begin.height > _end.height and begin.height - _end.height or _end.height - begin.height
    end

    local blend_range
    if begin.blend or _end.blend then
      begin.blend = begin.blend or 0
      _end.blend = _end.blend or 0
      blend_range = begin.blend > _end.blend and begin.blend - _end.blend or _end.blend - begin.blend
    end

    local row_speed
    if row_range then
      row_speed = row_range / (time * fps)
    end

    local col_speed
    if col_range then
      col_speed = col_range / (time * fps)
    end

    local width_speed
    if width_range then
      width_speed = width_range / (time * fps)
    end

    local height_speed
    if height_range then
      height_speed = height_range / (time * fps)
    end

    local blend_speed
    if blend_range then
      blend_speed = blend_range / (time * fps)
    end

    if row_speed and begin.row > _end.row then row_speed = row_speed * -1 end
    if col_speed and begin.col > _end.col then col_speed = col_speed * -1 end
    if width_speed and begin.width > _end.width then width_speed = width_speed * -1 end
    if height_speed and begin.height > _end.height then height_speed = height_speed * -1 end
    if blend_speed and begin.blend > _end.blend then blend_speed = blend_speed * -1 end

    local frame = 0
    local end_frame = time * fps
    local timer = vim.uv.new_timer()
    local delay = (time / (time * fps)) * 1000
    local function animate()
      self.state = self.state:add {
        row = row_speed,
        col = col_speed,
        width = width_speed,
        height = height_speed,
        blend = blend_speed,
      }
      self:update()
      frame = frame + 1
      if frame == end_frame then
        self.state = _end
        self.window.border = self.state.border
        self:update()
        if on_finish then
          on_finish()
        end
      else
        timer:start(delay, 0, vim.schedule_wrap(animate))
      end
    end
    animate()
    return self
  end

  ---add {handler} to {event} with {pattern}
  ---if {group} not exists create it
  ---@param event string|string[]
  ---@param pattern? string|string[]
  ---@param handler function|string
  ---@param group? string|integer
  ---@return windui.Window
  function Window:on(event, pattern, handler, group)
    if type(event) == "table" then
      for _, ev in ipairs(event) do
        self:on(ev, pattern, handler, group)
      end
    else
      if type(group) == "string" or group == nil then
        group = vim.api.nvim_create_augroup(group or "WindUI", { clear = false })
      end
      local event_opts = {
        pattern = pattern,
        group = group,
        buffer = self.buf,
        callback = type(handler) == "function" and handler or nil,
        command = type(handler) == "string" and handler or nil,
      }
      if not self._events[event] then
        self._events[event] = {}
      end
      table.insert(self._events[event], {
        pattern = pattern,
        group = group,
        callback = event_opts.callback,
        command = event_opts.command,
      })

      if not self.win then return self end
      vim.api.nvim_create_augroup("WindUI", { clear = false })
      vim.api.nvim_create_autocmd(event, event_opts)
    end
    return self
  end

  ---remove {event} handler with {pattern}
  ---@param event string|string[]
  ---@param pattern? string|string[]
  ---@param group? string|integer
  ---@return windui.Window
  function Window:off(event, pattern, group)
    if type(event) == "table" then
      for _, ev in ipairs(event) do
        self:off(ev, pattern, group)
      end
    else
      if self._events[event] then
        self._events[event] = vim.tbl_filter(function(val)
          if not group and not pattern then return false end
          if type(group) == "string" then
            group = vim.api.nvim_create_augroup(group, { clear = false })
          end
          local res = true
          if pattern then
            res = val.pattern ~= pattern
          end
          if group then
            res = res and val.group ~= group
          end
          return res
        end, self._events[event])
      end

      if not self.win then return self end
      vim.api.nvim_clear_autocmds({
        event = event,
        pattern = pattern,
        buffer = self.buf,
        group = "WindUI",
      })
    end
    return self
  end

  ---play {anim} on window
  ---@param anim windui.Animation
  ---@param on_finish? function
  ---@return windui.Window
  function Window:play(anim, on_finish)
    if not self.win then return self end
    anim:play(self, on_finish)
    return self
  end

  ---focus to the window
  ---@return windui.Window
  function Window:focus()
    vim.api.nvim_set_current_win(self.win)
    return self
  end
end)

return Window
