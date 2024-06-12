---@class windui.Window
local Window = {
  _window = {
    col = 0,
    row = 0,
    relative = "editor",
    width = 20,
    height = 8,
    border = "single",
    style = "minimal",
    hide = false,
    focusable = true,
  },
  _mappings = {},
}

---create a new Window
function Window.new(config)
  local t = {}
  setmetatable(t, {
    __index = Window,
  })
  if config then
    t._window = vim.tbl_extend('force', t._window, config)
  end
  return t
end

---open the Window
function Window:open(enter, opts)
  opts = vim.tbl_extend("force", {} --[[@as windui.Window.OpenOpts]], opts or {})
  if self.win or self.buf then return end
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
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = self.buf,
    callback = function()
      self.win = nil
      self.buf = nil
    end
  })

  self.win = vim.api.nvim_open_win(self.buf, enter, self._window)
end

---close the window
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
    vim.api.nvim_buf_delete(self.buf --[[@as integer]], { force = force })
    self.buf = nil
  end
end

---add mapping to window
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
end

---delete mapping from window
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
end

return Window
