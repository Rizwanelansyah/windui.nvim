local flr = math.floor
---@alias windui.border "none"|"single"|"rounded"|"double"|"solid"|string[]|string[][]
---@alias windui.anim_frame.position "left" | "top_left" | "top" | "top_right" | "right" | "bottom_right" | "bottom" | "bottom_left" | "center"

---@class windui.WindowState
---@field col number
---@field row number
---@field width number
---@field height number
---@field border windui.border
local WindowState = {
  col = 0,
  row = 0,
  width = 0,
  height = 0,
}

---@generic T
---@alias windui.wrap fun(value: T): T
---@alias windui.anim_frame.opts { col?: number, row?: number, width?: number, height?: number, border?: windui.border }
---@alias windui.anim_frame.map_opts { col?: windui.wrap<number>, row?: windui.wrap<number>, width?: windui.wrap<number>, height?: windui.wrap<number>, border?: windui.wrap<windui.border> }

---create new window state
---@param opts? windui.anim_frame.opts
---@return windui.WindowState
function WindowState.new(opts)
  local o = {}
  setmetatable(o, {
    __index = WindowState,
  })
  if opts then
    o.col = opts.col or WindowState.col
    o.row = opts.row or WindowState.row
    o.width = opts.width or WindowState.width
    o.height = opts.height or WindowState.height
    o.border = opts.border or WindowState.border
  end
  return o
end

---clone window state
---@param opts? windui.anim_frame.opts
---@return windui.WindowState
function WindowState:clone(opts)
  local o = {}
  setmetatable(o, {
    __index = WindowState,
  })
  opts = opts or {}
  o.col = opts.col or self.col
  o.row = opts.row or self.row
  o.width = opts.width or self.width
  o.height = opts.height or self.height
  return o
end

---modify window state
---@param opts windui.anim_frame.opts
---@return windui.WindowState
function WindowState:add(opts)
  local state = self:clone()
  for opt, value in pairs(opts) do
    state[opt] = state[opt] + value
  end
  return state
end

---map fields on {self} with field on {opts}
---@param opts windui.anim_frame.map_opts
---@return windui.WindowState
function WindowState:map(opts)
  local animf = self:clone()
  for key, map in pairs(opts) do
    animf[key] = map(animf[key])
  end
  return animf
end

---move window state to {direction}
---@param direction windui.anim_frame.position
---@return windui.WindowState
function WindowState:move_to(direction)
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

return WindowState
