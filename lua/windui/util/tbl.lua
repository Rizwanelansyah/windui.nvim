local M = {}

---clone the table and the metatable
---@generic T
---@param t T
---@return T
function M.clone(t)
  local new_t = {}
  for key, value in pairs(t) do
    new_t[key] = value
  end
  local mt = {}
  for key, value in pairs(getmetatable(t)) do
    mt[key] = value
  end
  setmetatable(new_t, mt)
  return new_t
end

return M
