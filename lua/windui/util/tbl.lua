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

---ia {tbl} instance of {class_name}
---@param tbl table
---@param class_name string
---@return boolean
function M.instance_of(tbl, class_name)
  if tbl.class_name == class_name then
    return true
  end
  local mt = getmetatable(tbl)
  if mt and mt.__index and type(mt.__index) == "table" then
    return M.instance_of(mt.__index, class_name)
  else
    return false
  end
end

return M
