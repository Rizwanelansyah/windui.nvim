local M = {}

---replace text on string at {pos}
---@param s string
---@param pos [integer, integer]
---@param new string
---@return string
function M.replace(s, pos, new)
  local start = ""
  for i = 0, pos[1] - 2 do
    start = start .. vim.fn.nr2char(vim.fn.strgetchar(s, i))
  end
  local end_ = ""
  for i = pos[2], vim.fn.strchars(s) - 1 do
  end_ = end_ .. vim.fn.nr2char(vim.fn.strgetchar(s, i))
  end
  return start .. new .. end_
end

return M
