---@class windui.Animation.Frame
---@field time integer
---@field fps integer
---@field frame windui.WindowState

---@class windui.Animation
---@field class_name string
---@field frames windui.Animation.Frame[]
local Animation = {
  class_name = "Animation",
}

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
---@param comp windui.UIComponent
---@param on_finish? function
function Animation:play(comp, on_finish)
  local i = 1
  local anim = coroutine.wrap(function()
    for _, frame in ipairs(self.frames) do
      local co = coroutine.running()
      i = i + 1
      comp:animate(frame.time, frame.fps, frame.frame, function()
        coroutine.resume(co)
      end)
      coroutine.yield()
    end
    if on_finish then
      on_finish()
    end
  end)

  local timer = vim.uv.new_timer()
  timer:start(0, 0, vim.schedule_wrap(anim))
end

return Animation
