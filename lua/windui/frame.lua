local Window = require("windui.window")
local util = require("windui.util")
local class = require("classic.class")
local match = require("classic.match")
local class_of = require("classic.class_of")

---@class windui.Frame.opts
---@field padding? windui.spacing|integer

---@class windui.Frame: windui.Window
---@field child windui.Component
---@field padding windui.padding
---
---@field private _update fun(self: self, state?: windui.WindowState): self
---
---@field new fun(config?: vim.api.keyset.win_config, child: windui.Component, opts?: windui.Frame.opts): windui.Frame
local Frame = {}
class(Frame, Window, function(C)
  ---update frame
  ---@param state windui.WindowState
  ---@return windui.Frame
  function Frame:_update(state)
    if state then
      self.state = state
    end
    local bordered = self.state:is_bordered()
    local cbordered = self.child.state:is_bordered()
    self.child.state.row = self.state.row + (bordered.top and 1 or 0) + self.padding.top
    self.child.state.col = self.state.col + (bordered.left and 1 or 0) + self.padding.left
    self.child.state.height = self.state.height - self.padding.top - self.padding.bottom
    self.child.state.width = self.state.width - self.padding.left - self.padding.right

    if match(class_of(self.child), Window) then
      self.child.state.height = self.child.state.height - (cbordered.top and 1 or 0) - (cbordered.bottom and 1 or 0)
      self.child.state.width = self.child.state.width - (cbordered.left and 1 or 0) - (cbordered.right and 1 or 0)
    end

    local zindex = self.win and vim.api.nvim_win_get_config(self.win).zindex or (self.state.zindex or 1)
    self.child.state.zindex = zindex + 1
    return self
  end

  C.public()
  Frame.child = nil
  Frame.padding = nil

  ---create new frame window
  ---@param config vim.api.keyset.win_config
  ---@param child windui.Component
  ---@param opts? windui.Frame.opts
  function Frame:__init(config, child, opts)
    Window.__init(self, config)
    opts = vim.tbl_extend('force', {
      padding = util.ui.spacing(0),
    }, opts or {})
    self.child = child
    self.padding = type(opts.padding) == "number" and util.ui.spacing(opts.padding) or opts.padding
  end

  ---open frame
  ---@param enter boolean
  ---@return windui.Frame
  function Frame:open(enter)
    if self.win then return self end
    self:_update()
    Window.open(self, false)
    local zindex = self.win and vim.api.nvim_win_get_config(self.win).zindex or (self.window.zindex or 1)
    self.child.state.zindex = zindex + 1
    self.child:open(enter)
    return self
  end

  ---close frame
  ---@param force boolean
  ---@return windui.Frame
  function Frame:close(force)
    if not self.win then return self end
    self.child:close(force)
    Window.close(self, force)
    return self
  end

  ---update frame
  ---@param state windui.WindowState
  ---@param update_child boolean?
  ---@return windui.Frame
  function Frame:update(state, update_child)
    if update_child == nil then
      update_child = false
    end
    self:_update(state)
    Window.update(self)
    local zindex = self.win and vim.api.nvim_win_get_config(self.win).zindex or (self.state.zindex or 1)
    self.child.state.zindex = zindex + 1
    if update_child then
      self.child:update()
    end
    return self
  end

  ---focus to the child
  ---@return windui.Frame
  function Frame:focus()
    self.child:focus()
    return self
  end

  ---add mapping to child
  ---@param mode string|string[]
  ---@param lhs string
  ---@param rhs string|function
  ---@return windui.Frame
  function Frame:map(mode, lhs, rhs)
    self.child:map(mode, lhs, rhs)
    return self
  end

  ---remove mapping from child
  ---@param mode string|string[]
  ---@param lhs string
  ---@return windui.Frame
  function Frame:unmap(mode, lhs)
    self.child:unmap(mode, lhs)
    return self
  end

  ---animate frame
  ---@param time number
  ---@param fps integer
  ---@param state windui.WindowState
  ---@param on_finish? function
  ---@return windui.Frame
  function Frame:animate(time, fps, state, on_finish)
    self:_update()
    Window.animate(self, time, fps, state)
    self.child:animate(time, fps, self.child.state, on_finish)
    return self
  end
end)


return Frame
