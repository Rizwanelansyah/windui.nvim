---get the class of the object
---@param obj table
---@return classic.Class
local function class_of(obj)
  return getmetatable(obj or {}).__class
end

return class_of
