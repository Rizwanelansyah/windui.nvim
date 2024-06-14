---@class windui.Animation
---@field frames fun(self: windui.Window, next: function)[]
local Animation = {}

---create new animation
---@param frames ({ time?: integer, fps?: integer, anim_frame?: windui.AnimationFrame|windui.anim_frame.position }|fun(self: windui.Window))[]
---@return windui.Animation
function Animation.new(frames)
  local o = { frames = {} }
  setmetatable(o, {
    __index = Animation,
  })
  for _, frame in ipairs(frames) do
    if type(frame) == "function" then
      table.insert(o.frames, frame)
    else
      table.insert(o.frames, function(win, next)
        local anim_frame
        if type(frame.anim_frame) == "string" then
          anim_frame = win.anim_frame:move_to(frame.anim_frame)
        else
          anim_frame = win.anim_frame:clone(frame.anim_frame)
        end
        win:animate(frame.time, frame.fps, anim_frame, next)
      end)
    end
  end
  o.len = #frames
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
      frame(win, next)
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
