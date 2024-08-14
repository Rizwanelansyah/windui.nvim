---match 2 class
---@param c1 classic.Class
---@param c2 classic.Class
---@return boolean
local function match(c1, c2)
  if c1 == c2 then return true end
  local parent = (getmetatable(c1 or {}) or {}).__parent
  if parent then
    return match(parent, c2)
  end
  parent = (getmetatable(c2 or {}) or {}).__parent
  if parent then
    return match(parent, c1)
  end
  return false
end

return match
