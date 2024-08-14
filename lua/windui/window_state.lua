local class = require("classic.class")
local flr = math.floor
local util = require("windui.util")
---@alias windui.border "none"|"single"|"rounded"|"double"|"solid"|"shadow"|string[]|string[][]
---@alias windui.relative 'editor'|'win'|'cursor'|'mouse'
---@alias windui.anim_frame.position "left" | "top_left" | "top" | "top_right" | "right" | "bottom_right" | "bottom" | "bottom_left" | "center"

---@generic T
---@alias windui.wrap fun(value: T): T
---@alias windui.window_frame.opts { zindex?: integer, col?: number, row?: number, width?: number, height?: number, border?: windui.border, blend?: integer, relative?: windui.relative, win?: integer }
---@alias windui.anim_frame.map_opts { zindex?: windui.wrap<integer>, col?: windui.wrap<number>, row?: windui.wrap<number>, width?: windui.wrap<number>, height?: windui.wrap<number>, border?: windui.wrap<windui.border>, bend?: windui.wrap<integer>, relative?: windui.wrap<windui.relative>, win?: windui.wrap<integer> }

---@class windui.WindowState
---@field col? number
---@field row? number
---@field width? number
---@field height? number
---@field border? windui.border
---@field blend? integer
---@field zindex? integer
---@field relative? windui.relative
---@field win? integer
---
---create new window state
---@field new fun(opts?: windui.window_frame.opts): windui.WindowState
local WindowState = {}
class(WindowState, function(C)
  C.public()
  WindowState.col = nil
  WindowState.row = nil
  WindowState.width = nil
  WindowState.height = nil
  WindowState.blend = nil
  WindowState.border = nil
  WindowState.zindex = nil
  WindowState.relative = nil
  WindowState.win = nil

  ---@param opts? windui.window_frame.opts
  function WindowState:__init(opts)
    if opts then
      self.col = opts.col or 0
      self.row = opts.row or 0
      self.width = opts.width or 1
      self.height = opts.height or 1
      self.border = opts.border
      self.blend = opts.blend
      self.zindex = opts.zindex
      self.relative = opts.relative
      self.win = opts.win
    end
    if self.relative ~= 'win' then
      self.win = nil
    end
  end

  ---clone window state
  ---@param opts? windui.window_frame.opts
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
    o.blend = opts.blend or self.blend
    o.border = opts.border or self.border
    o.zindex = opts.zindex or self.zindex
    o.relative = opts.relative or self.relative
    o.win = opts.win or self.win
    if o.relative ~= 'win' then
      o.win = nil
    end
    return o
  end

  ---modify window state
  ---@param opts windui.window_frame.opts
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
    self.relative = 'editor'
    self.win = nil
    local bordered = self:is_bordered() --[[@as table]]
    bordered.vertical = bordered.top and bordered.bottom
    bordered.horizontal = bordered.left and bordered.right
    local lines = vim.o.lines
    local columns = vim.o.columns
    return ({
      top_left = function() return self:clone { row = 0, col = 0 } end,
      top = function()
        return self:clone {
          row = 0,
          col = flr(columns / 2) - flr(self.width / 2) - (bordered.horizontal and 1 or 0),
        }
      end,
      top_right = function()
        return self:clone {
          row = 0,
          col = columns - self.width - (bordered.left and 1 or 0) - (bordered.right and 1 or 0),
        }
      end,
      right = function()
        return self:clone {
          row = flr(lines / 2) - (self.height / 2) - (bordered.vertical and 1 or 0),
          col = columns - self.width - (bordered.left and 1 or 0) - (bordered.right and 1 or 0),
        }
      end,
      bottom_right = function()
        return self:clone {
          row = lines - self.height - (bordered.top and 1 or 0) - (bordered.bottom and 1 or 0),
          col = columns - self.width - (bordered.left and 1 or 0) - (bordered.right and 1 or 0),
        }
      end,
      bottom = function()
        return self:clone {
          row = lines - self.height - (bordered.top and 1 or 0) - (bordered.bottom and 1 or 0),
          col = flr(columns / 2) - flr(self.width / 2) - (bordered.horizontal and 1 or 0),
        }
      end,
      bottom_left = function()
        return self:clone {
          row = lines - self.height - (bordered.top and 1 or 0) - (bordered.bottom and 1 or 0),
          col = 0,
        }
      end,
      left = function()
        return self:clone {
          row = flr(lines / 2) - flr(self.height / 2) - (bordered.vertical and 1 or 0),
          col = 0,
        }
      end,
      center = function()
        return self:clone {
          row = flr(lines / 2) - (self.height / 2) - (bordered.vertical and 1 or 0),
          col = flr(columns / 2) - flr(self.width / 2) - (bordered.horizontal and 1 or 0),
        }
      end,
    })[direction]()
  end

  ---check if each side state is bordered
  ---@return { top: boolean, right: boolean, bottom: boolean, left: boolean }
  function WindowState:is_bordered()
    local bordered = {}
    local parts = util.ui.get_border_parts(self.border)
    bordered.top = parts[2] ~= ''
    bordered.right = parts[4] ~= ''
    bordered.bottom = parts[6] ~= ''
    bordered.left = parts[8] ~= ''
    return bordered
  end
end)

return WindowState
