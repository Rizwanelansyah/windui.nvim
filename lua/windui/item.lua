local class = require("classic.class")

---@class windui.Menu.Item: classic.Class
---@field text string|string[][]
---@field value any
---
---@field new fun(value: any, text?: string|string[])
local Item = {}
class(Item, function(C)
  C.public()
  Item.text = nil
  Item.value = nil

---create new item
  ---@param value any
  ---@param text? string|string[][]
  function Item:__init(value, text)
    self.value = value
    self.text = tostring(value)
    if text then
      self.text = text
    end
  end

  ---render this item into buffer
  ---@param buf integer
  ---@param line integer
  function Item:render(buf, line)
    if type(self.text) == "string" then
      ---@diagnostic disable-next-line: assign-type-mismatch
      vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { self.text })
    else
      local len = 0
      local hls = {}
      local text_line = ""
      ---@diagnostic disable-next-line: param-type-mismatch
      for i, text in ipairs(self.text) do
        local txtlen = vim.fn.strchars(text[1])
        text_line = text_line .. text[1]
        hls[i] = { len, len + txtlen, text[2] or "Normal" }
        len = len + txtlen
      end
      vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { text_line })
      for _, hl in ipairs(hls) do
        vim.api.nvim_buf_add_highlight(buf, vim.api.nvim_create_namespace("WindUI"), hl[3], line - 1, hl[1], hl[2])
      end
    end
  end
end)

return Item
