---@class windui.Geometry
---@field col integer
---@field row integer
---@field width integer
---@field height integer
local Geometry = {
  col = 0,
  row = 0,
  width = 0,
  height = 0,
}

---create new geometry
---@param opts? { col?: integer, row?: integer, width?: integer, height?: integer }
---@return windui.Geometry
function Geometry:new(opts)
  local o = {}
  setmetatable(o, {
    __index = self,
  })
  if opts then
    o.col = opts.col or self.col
    o.row = opts.row or self.row
    o.width = opts.width or self.width
    o.height = opts.height or self.height
  end
  return o
end

---modify geometry
---@param opts { col?: integer, row?: integer, width?: integer, height?: integer }
---@return windui.Geometry
function Geometry:mod(opts)
  local geo = self:new()
  for opt, value in pairs(opts) do
    geo[opt] = geo[opt] + value
  end
  return geo
end

function Geometry:each(func)
  local geo = self:new()
  geo.row = func(self.row)
  geo.col = func(self.col)
  geo.width = func(self.width)
  geo.height = func(self.height)
  return geo
end

return Geometry
