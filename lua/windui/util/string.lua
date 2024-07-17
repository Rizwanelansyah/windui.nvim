local umath = require("windui.util.math")
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

---align the string
---@param s string
---@param width integer
---@param alignment "center"|"left"|"right"|"between"
function M.align(s, width, alignment)
  local res = ""
  if alignment == "between" then
    local strings = vim.split(s, " ", { trimempty = true })
    if #strings == 1 then
      return M.align(s, width, "center")
    end
    local total_width = width
    for _, str in ipairs(strings) do
      total_width = total_width - #str
    end
    local widths = umath.div_list_int(total_width, #strings - 1)
    res = strings[1]
    for i = 2, #strings do
      res = res .. string.rep(" ", widths[i-1]) .. strings[i]
    end
  else
    s = vim.trim(s)
    res = s
    local space_to_left = alignment == "right"
    while vim.fn.strchars(res) < width do
      if space_to_left then
        res = " " .. res
      else
        res = res .. " "
      end
      if alignment == "center" then
        space_to_left = not space_to_left
      end
    end
  end
  return res
end

return M
