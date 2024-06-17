local Window = require("windui.window")
local Item = require("windui.item")

---@class windui.Menu: windui.Window
---@field on_choice fun(self: windui.Menu, value: any)
---@field class_name string
---@field items (windui.Menu.Item | windui.Menu)[]
---@field parent? windui.Menu
---@field name string
local Menu = {
  class_name = "Menu",
  on_choice = function() end,
}
setmetatable(Menu, { __index = Window })

---create new menu window
---@param config vim.api.keyset.win_config
---@param items (windui.Menu.Item | windui.Menu)[]
---@param name? string
---@return windui.Menu
function Menu.new(config, items, name)
  local self = Window.new(config) --[[@as windui.Menu ]]
  setmetatable(self, {
    __index = Menu,
  })
  self.items = items
  self.name = name or "Menu"
  if self.window.border ~= "none" then
    self.window.title = self.window.title or self.name
  end
  self.opt.win.cursorline = true
  self.opt.win.winhl = "CursorLine:PmenuSel"
  self.opt.win.scrolloff = 0

  local close = function()
    if self.parent then
      self.parent:focus()
    end
    self:close(true)
  end
  self:map('n', '<Left>', function() if self.parent then close() end end)
  self:map('n', '<Right>', function() if self:get_item().class_name == Menu.class_name then self:choice() end end)
  self:map('n', '<Down>', function() self:move(1, true) end)
  self:map('n', '<Up>', function() self:move(-1, true) end)

  self:map('n', 'h', function() if self.parent then close() end end)
  self:map('n', 'l', function() if self:get_item().class_name == Menu.class_name then self:choice() end end)
  self:map('n', 'j', function() self:move(1, true) end)
  self:map('n', 'k', function() self:move(-1, true) end)

  self:map('n', '<ESC>', close)
  self:map('n', '<CR>', function() self:choice() end)
  return self
end

---open menu
---@param enter boolean
function Menu:open(enter)
  vim.cmd("normal! 0")
  Window.open(self, enter)
  local pos = vim.api.nvim_win_get_cursor(self.win)
  if self.state.border ~= "none" then
    self.window.title = string.format("%s (%d/%d)", self.name, pos[1], vim.fn.line('$'))
    self:update()
  end

  for i, item in ipairs(self.items) do
    if item.class_name == Item.class_name then
      item:render(self.buf, i)
    elseif item.class_name == Menu.class_name then
      vim.api.nvim_buf_set_lines(self.buf, i - 1, i, false, { "> " .. item.name })
    end
  end
  vim.bo[self.buf].readonly = true
  vim.bo[self.buf].modifiable = false
end

---move selection to +{range}
---@param range integer
---@param cycle boolean
function Menu:move(range, cycle)
  if not self.win then return end
  local pos = vim.api.nvim_win_get_cursor(self.win)
  local ok, _ = pcall(vim.api.nvim_win_set_cursor, self.win, { pos[1] + range, 0 })
  if cycle and not ok then
    vim.api.nvim_win_set_cursor(self.win, { range < 0 and vim.fn.line('$') or 1, 0 })
  end
  pos = vim.api.nvim_win_get_cursor(self.win)
  if self.state.border ~= "none" then
    self.window.title = string.format("%s (%d/%d)", self.name, pos[1], vim.fn.line('$'))
    self:update()
  end
end

---get item under cursor
---@return windui.Menu|windui.Menu.Item
function Menu:get_item()
  return self.items[vim.api.nvim_win_get_cursor(self.win)[1]]
end

---set the cursor position to the specified item
---@param value (fun(item: windui.Menu|windui.Menu.Item): boolean)|any
function Menu:set_selected(value)
  if not self.win then return end
  local row = vim.api.nvim_win_get_cursor(self.win)[1]
  for i, item in ipairs(self.items) do
    if type(value) == "function" then
      if value(item) then
        row = i
        break
      end
    else
      if item.class_name == Item.class_name then
        if item.value == value then
          row = i
          break
        end
      elseif item.class_name == Menu.class_name then
        if item.name == value then
          row = i
          break
        end
      end
    end
  end
  vim.api.nvim_win_set_cursor(self.win, { row, 0 })
end

---exit and execute self.on_choice passed
---with selected item
function Menu:choice()
  local item = self:get_item()
  if item then
    if item.class_name == Item.class_name then
      self:close(true)
      self:on_choice(item.value)
    elseif item.class_name == Menu.class_name then
      item.parent = self
      item.on_choice = function(_, value)
        item:close(true)
        self:on_choice(value)
        self:close(true)
      end
      item.state = item.state:clone {
        relative = 'win',
        win = self.win,
        col = self.state.width,
        row = vim.api.nvim_win_get_cursor(self.win)[1] - 1,
      }
      item.window.zindex = vim.api.nvim_win_get_config(self.win).zindex + 1
      item:open(true)
    end
  end
end

return Menu
