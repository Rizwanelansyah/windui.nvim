local Window = require("windui.window")

---@class windui.InteractiveWindow : windui.Window
---@field content windui.IWComponent[]
local InteractiveWindow = {
  class_name = "InteractiveWindow",
}

setmetatable(InteractiveWindow, { __index = Window })

---create new interactive window
---@param config vim.api.keyset.win_config
---@param content windui.IWComponent[]?
---@return windui.InteractiveWindow
function InteractiveWindow.new(config, content)
  local o = Window.new(config) --[[@as windui.InteractiveWindow]]
  setmetatable(o, { __index = InteractiveWindow })
  o.content = content or {}
  return o
end

---open window
---@param enter boolean?
function InteractiveWindow:open(enter)
  Window.open(self, enter)
  if not self.win then return end
  vim.bo[self.buf].readonly = false
  vim.bo[self.buf].modifiable = true
  for i = 1, self.state.height do
    vim.api.nvim_buf_set_lines(self.buf, i - 1, i, false, { string.rep(" ", self.state.width) })
  end
  for i, comp in ipairs(self.content) do
    comp.parent = {
      height = self.state.height,
      width = self.state.width,
    } --[[@as windui.IWComponent ]]
    comp:draw(self, { i - 1, 0 })
  end
  vim.bo[self.buf].readonly = true
  vim.bo[self.buf].modifiable = false
end

return InteractiveWindow
