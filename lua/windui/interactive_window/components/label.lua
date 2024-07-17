local util = require("windui.util")
local Base = require("windui.interactive_window.components.base")

---@class windui.IWComponent.Label : windui.IWComponent
---@field class_name string
---@field text string
---@field wrap "char"|"word"|"none"
---@field width integer
---@field height integer
---@field col integer
---@field row integer
---@field hl string
---@field text_hl string
---@field padding windui.spacing
---@field margin windui.spacing
---@field align "center"|"left"|"right"|"between"
local Label = {
  class_name = "IWComponent.Label",
}

setmetatable(Label, {
  __index = Base,
  __call = function(t, ...)
    return t.new(...)
  end
})

---@class windui.IWComponent.Label.opts
---@field text? string
---@field wrap? "char"|"word"|"none"
---@field row? integer
---@field col? integer
---@field width? integer
---@field height? integer
---@field hl? string
---@field text_hl? string
---@field padding? windui.spacing
---@field margin? windui.spacing
---@field align? "center"|"left"|"right"|"between"

---create new text component
---@param opt string|windui.IWComponent.Label.opts
---@return windui.IWComponent.Label
function Label.new(opt)
  local o = Base.new() --[[@as windui.IWComponent.Label]]
  setmetatable(o, { __index = Label })
  ---@type windui.IWComponent.Label.opts
  local default = {
    text = "",
    wrap = "word",
    width = 0,
    height = 0,
    row = 0,
    col = 0,
    hl = "",
    text_hl = "",
    align = "left",
    padding = util.ui.spacing(0),
    margin = util.ui.spacing(0),
  }
  if type(opt) == "string" then
    for k, v in pairs(default) do
      o[k] = v
    end
    o.text = opt or ""
  else
    for k, v in pairs(default) do
      if opt[k] ~= nil then
        o[k] = opt[k]
      else
        o[k] = v
      end
    end
  end
  return o
end

---draw the component to {win} on position {pos}
---@param win windui.InteractiveWindow
---@param pos [integer, integer]?
function Label:draw(win, pos)
  if self.drawed then
    for i = self.row, self.row + self.padding.top do
      vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), "Normal", i, self.col,
        self.col + self.width)
    end
    for i = self.row + 1, self.row + self.height - 1 do
      local line = vim.api.nvim_buf_get_lines(win.buf, i, i + 1, false)[1]
      local new_line = util.string.replace(line, { self.col + 1, self.col + self.width }, string.rep(" ", self.width))
      vim.api.nvim_buf_set_lines(win.buf, i, i + 1, false, { new_line })
      vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), "Normal", i, self.col,
        self.col + self.width)
    end
    for i = self.row + self.height - self.padding.bottom, self.row + self.height - 1 do
      vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), "Normal", i, self.col,
        self.col + self.width)
    end
  end
  if pos then
    self.row = pos[1]
    self.col = pos[2]
  end

  local no_width = self.width < 1
  if self.width < 1 then
    self.width = self.parent.width
  end

  local content = {}
  local cur_width = 0
  local cur_line = 1
  local max_width = self.width - self.padding.left - self.padding.right
  local max_height = self.height - self.padding.top - self.padding.bottom
  if self.wrap ~= "none" then
    self.text = self.text:gsub("%s", " ")
  end

  if self.wrap == "word" then
    local words = vim.split(self.text, " ")
    for _, word in ipairs(words) do
      if self.width ~= 0 and vim.fn.strchars(content[cur_line] or "") + vim.fn.strchars(word) > max_width then
        cur_line = cur_line + 1
      end
      while vim.fn.strchars(word) > 0 do
        local prev_word = word:sub(1, self.width == 0 and -1 or max_width)
        content[cur_line] = (content[cur_line] or "") .. prev_word
        if prev_word == word then break end
        local new_word = ""
        if self.width ~= 0 then
          for i = max_width, vim.fn.strchars(word) do
            new_word = new_word .. vim.fn.nr2char(vim.fn.strgetchar(word, i))
          end
        end
        word = new_word
        if vim.fn.strchars(word) > 0 then
          cur_line = cur_line + 1
        end
      end
      if not self.width ~= 0 or vim.fn.strchars(content[cur_line]) < max_width then
        if vim.fn.strchars(content[cur_line] or "") < max_width then
          content[cur_line] = content[cur_line] .. " "
        end
      end
      if self.height > 0 and cur_line > max_height then
        content[max_height + 1] = nil
        break
      end
    end
  else
    for i = 1, vim.fn.strchars(self.text) do
      local char = vim.fn.nr2char(vim.fn.strgetchar(self.text, i - 1))
      if char == "\n" then
        cur_width = 0
        cur_line = cur_line + 1
        goto continue
      end
      cur_width = cur_width + vim.fn.strchars(char)
      content[cur_line] = (content[cur_line] or "") .. char
      if char == "\n" then
        cur_line = cur_line + 1
        cur_width = 0
      end
      if self.width ~= 0 and cur_width >= max_width then
        if self.wrap == "none" then
          break
        end
        cur_line = cur_line + 1
        cur_width = 0
      end
      if self.height ~= 0 and cur_line > max_height then
        content[max_height + 1] = nil
        break
      end
      ::continue::
    end
  end

  local width = self.width
  for _, text in ipairs(content) do
    local len = #text
    if width < len then
      width = len
    end
  end
  self.width = width

  if #content > self.parent.height then
    for i = self.parent.height + 1, #content do
      content[i] = nil
    end
  end
  if self.height == 0 then
    self.height = #content
  end

  if no_width then
    local new_width = 0
    for _, w in ipairs(content) do
      if #w > new_width then
        new_width = #w
      end
    end
    self.width = new_width
  end
  for i = self.row, self.row + self.padding.top do
    vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), self.hl, i, self.col,
      self.col + self.width)
  end
  for i, text in ipairs(content) do
    text = util.string.align(text, self.width - self.padding.left - self.padding.right - 2, self.align)
    local byte_len = #text
    local rest_byte = 0
    while byte_len ~= vim.fn.strchars(text) do
      text = text .. " "
      rest_byte = rest_byte + 1
    end
    local line = vim.api.nvim_buf_get_lines(win.buf, self.row - 1 + i + self.padding.top, self.row + i + self.padding
      .top, false)[1]
    local new_line = util.string.replace(line,
      { self.col + 1 + self.padding.left, self.col + byte_len + self.padding.left },
      text)
    vim.api.nvim_buf_set_lines(win.buf, self.row - 1 + i + self.padding.top, self.row + i + self.padding.top, false,
      { new_line })
    if self.hl ~= "" then
      vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), self.hl,
        self.row - 1 + i + self.padding.top,
        self.col, self.col + self.width + rest_byte)
    end
    if self.text_hl ~= "" then
      vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), self.text_hl,
        self.row - 1 + i + self.padding.top, self.col + self.padding.left, self.col + byte_len + self.padding.left)
    end
  end
  for i = self.row + self.height - self.padding.bottom, self.row + self.height - 1 do
    vim.api.nvim_buf_add_highlight(win.buf, vim.api.nvim_create_namespace("Windui"), self.hl, i, self.col,
      self.col + self.width)
  end
  self.drawed = true
end

return Label
