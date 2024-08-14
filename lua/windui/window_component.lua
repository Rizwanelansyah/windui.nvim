local class = require("classic.class")
local unimpl = function()
  error("method not implemented yet")
end

---@class windui.Component: classic.Class
---@field state windui.WindowState
---
---@field new fun(): windui.Component
---@field open fun(self: self, enter?: boolean): self
---@field close fun(self: self, force?: boolean): self
---@field update fun(self: self, state?: windui.WindowState): self
---@field focus fun(self: self): self
---@field map fun(self: self, mode: string|string[], lhs: string, rhs: string|fun(self: self)): self
---@field unmap fun(self: self, mode: string|string[], lhs: string): self
---@field on fun(self: self, event: string|string[], pattern?: string|string[], handler: string|fun(self: self), group?: string|integer): self
---@field off fun(self: self, event: string|string[], pattern?: string|string[], group?: string|integer): self
---@field after_open fun(self: self)
---@field before_close fun(self: self, close: function)
---@field animate fun(self: self, time: number, fps: integer, state: windui.WindowState, on_finish?: function): self
local Component = {}
class(Component, function(C)
  C.public()
  Component.state = nil
  Component.after_open = nil
  Component.before_close = nil

  function Component:animate()
    unimpl()
    return self
  end

  function Component:off()
    unimpl()
    return self
  end

  function Component:on()
    unimpl()
    return self
  end

  function Component:unmap()
    unimpl()
    return self
  end

  function Component:map()
    unimpl()
    return self
  end

  function Component:focus()
    unimpl()
    return self
  end

  function Component:update()
    unimpl()
    return self
  end

  function Component:close()
    unimpl()
    return self
  end

  function Component:open()
    unimpl()
    return self
  end
end)

return Component
