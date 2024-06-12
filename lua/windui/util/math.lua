local M = {}

---make the number positive
---@param num float
---@return float
function M.positive(num)
  if num < 0 then return -num end
  return num
end

return M
