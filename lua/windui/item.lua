---@class windui.Menu.Item
---@field text string
---@field value any
---@field class_name string
local Item = {
  class_name = "Item"
}

---create new item
---@param value any
---@param text? string
---@return table
function Item.new(value, text)
  local o = {}
  setmetatable(o, { __index = Item })
  o.value = value
  o.text = tostring(text or value)
  return o
end

---render this item into buffer
---@param buf integer
---@param line integer
function Item:render(buf, line)
  vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { self.text })
end

return Item
