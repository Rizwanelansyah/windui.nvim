local flr = math.floor
---@alias border "none"|"single"|"rounded"|"double"|"solid"|string[]|string[][]
---@alias windui.anim_frame.position "left" | "top_left" | "top" | "top_right" | "right" | "bottom_right" | "bottom" | "bottom_left" | "center"

---@class windui.AnimationFrame
---@field col number
---@field row number
---@field width number
---@field height number
---@field border border
local AnimationFrame = {
  col = 0,
  row = 0,
  width = 0,
  height = 0,
  border = "none",
}

---@generic T
---@alias wrap fun(value: T): T

---@alias windui.anim_frame.opts { col?: number, row?: number, width?: number, height?: number, border?: border }
---@alias windui.anim_frame.map_opts { col?: wrap<number>, row?: wrap<number>, width?: wrap<number>, height?: wrap<number>, border?: wrap<border> }

---create new animation frame
---@param opts? windui.anim_frame.opts
---@return windui.AnimationFrame
function AnimationFrame.new(opts)
  local o = {}
  setmetatable(o, {
    __index = AnimationFrame,
  })
  if opts then
    o.col = opts.col or AnimationFrame.col
    o.row = opts.row or AnimationFrame.row
    o.width = opts.width or AnimationFrame.width
    o.height = opts.height or AnimationFrame.height
    o.border = opts.border or AnimationFrame.border
  end
  return o
end

---clone animation frame
---@param opts? windui.anim_frame.opts
---@return windui.AnimationFrame
function AnimationFrame:clone(opts)
  local o = {}
  setmetatable(o, {
    __index = AnimationFrame,
  })
  opts = opts or {}
  o.col = opts.col or self.col
  o.row = opts.row or self.row
  o.width = opts.width or self.width
  o.height = opts.height or self.height
  return o
end

---modify animation frame
---@param opts windui.anim_frame.opts
---@return windui.AnimationFrame
function AnimationFrame:add(opts)
  local animf = self:clone()
  for opt, value in pairs(opts) do
    animf[opt] = animf[opt] + value
  end
  return animf
end

---map fields on {self} with field on {opts}
---@param opts windui.anim_frame.map_opts
---@return windui.AnimationFrame
function AnimationFrame:map(opts)
  local animf = self:clone()
  for key, map in pairs(opts) do
    animf[key] = map(animf[key])
  end
  return animf
end

---move animation frame to {direction}
---@param direction windui.anim_frame.position
---@return windui.AnimationFrame
function AnimationFrame:move_to(direction)
  local bordered = not (self.border == "none")
  return ({
    left = function()
      return self:clone {
        row = flr(vim.o.lines / 2) - flr(self.height / 2) - (bordered and 1 or 0),
        col = 0,
      }
    end,
    top_left = function() return self:clone { row = 0, col = 0 } end,
    top = function()
      return self:clone {
        row = 0,
        col = flr(vim.o.columns / 2) - flr(self.width / 2) - (bordered and 1 or 0),
      }
    end,
    top_right = function()
      return self:clone {
        row = 0,
        col = vim.o.columns - self.width - (bordered and 1 or 0),
      }
    end,
    right = function()
      return self:clone {
        row = flr(vim.o.lines / 2) - (self.height / 2) - (bordered and 1 or 0),
        col = vim.o.columns - self.width - (bordered and 1 or 0),
      }
    end,
    bottom_right = function()
      return self:clone {
        row = vim.o.lines - self.height - (bordered and 1 or 0),
        col = vim.o.columns - self.width - (bordered and 1 or 0),
      }
    end,
    bottom = function()
      return self:clone {
        row = vim.o.lines - self.height - (bordered and 1 or 0),
        col = flr(vim.o.columns / 2) - flr(self.width / 2) - (bordered and 1 or 0),
      }
    end,
    bottom_left = function()
      return self:clone {
        row = vim.o.lines - self.height - (bordered and 1 or 0),
        col = 0,
      }
    end,
    center = function()
      return self:clone {
        row = flr(vim.o.lines / 2) - (self.height / 2) - (bordered and 1 or 0),
        col = flr(vim.o.columns / 2) - flr(self.width / 2) - (bordered and 1 or 0),
      }
    end
  })[direction]()
end

return AnimationFrame
