local M = {}

---div {a} to {b} length list
---with same size if possible
---@param a integer
---@param b integer
---@return integer[]
function M.div_list_int(a, b)
  local result = {}
  local sum = math.floor(a / b)
  for i = 1, b do
    result[i] = sum
  end
  sum = sum * b
  local i = 1
  while sum ~= a do
    sum = sum + 1
    result[i] = result[i] + 1
    i = i + 1
    if i > b then
      i = 1
    end
  end
  return result
end

return M
