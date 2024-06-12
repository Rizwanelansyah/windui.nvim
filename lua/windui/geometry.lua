---@class windui.Geometry
---@field col number
---@field row number
---@field width number
---@field height number
local Geometry = {
  col = 0,
  row = 0,
  width = 0,
  height = 0,
}

---create new geometry
---@param opts? { col?: number, row?: number, width?: number, height?: number }
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

---clone geometry
---@param opts? { col?: number, row?: number, width?: number, height?: number }
---@return windui.Geometry
function Geometry:clone(opts)
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
---@param opts { col?: number, row?: number, width?: number, height?: number }
---@return windui.Geometry
function Geometry:mod(opts)
  local geo = self:new()
  for opt, value in pairs(opts) do
    geo[opt] = geo[opt] + value
  end
  return geo
end

---call {func} for row, col, width, height
---and make the new one with that 
---@param func fun(value: number): number
---@return windui.Geometry
function Geometry:each(func)
  local geo = self:new()
  geo.row = func(self.row)
  geo.col = func(self.col)
  geo.width = func(self.width)
  geo.height = func(self.height)
  return geo
end

return Geometry
