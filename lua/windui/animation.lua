---@class windui.Animation.Frame
---@field time integer
---@field fps integer
---@field frame windui.WindowState

---@class windui.Animation
---@field frames windui.Animation.Frame[]
local Animation = {}

---create new animatio
---@param frames windui.Animation.Frame[]
---@return windui.Animation
function Animation.new(frames)
  local o = { frames = frames }
  setmetatable(o, {
    __index = Animation,
  })
  return o
end

---paly animation on {win}
---@param win windui.Window
---@param on_finish function
function Animation:play(win, on_finish)
  local i = 1
  local function next()
    local frame = self.frames[i]
    if frame then
      i = i + 1
      win:animate(frame.time, frame.fps, frame.frame, next)
    else
      if on_finish then
        on_finish()
      end
    end
  end

  local timer = vim.uv.new_timer()
  timer:start(0, 0, vim.schedule_wrap(next))
end

return Animation
