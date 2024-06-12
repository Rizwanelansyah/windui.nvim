---@class windui.Geometry
---@field row integer
---@field col integer
---@field width integer
---@field height integer

---@class windui.Window.OpenOpts

---@class windui.Window
---@field _window vim.api.keyset.win_config
---@field _mappings table<string, table<string, string|function>>
---@field content string? content of the Window
---@field win integer? window handle for this Window window
---@field buf integer? buffer number for this Window buffer
---@field new fun(config?: vim.api.keyset.win_config): windui.Window
---@field open fun(self: windui.Window, enter?: boolean, opts?: windui.Window.OpenOpts)
---@field close fun(self: windui.Window, enter?: boolean)
---@field map fun(self: windui.Window, mode: string|string[], lhs: string, rhs: string|function)
---@field unmap fun(self: windui.Window, mode: string|string[], lhs: string)
