local class = require("classic.class")

---@class windui.Animation.Frame
---@field time integer
---@field fps integer
---@field frame windui.WindowState

---@class windui.Animation: classic.Class
---@field frames windui.Animation.Frame[]
---
---create new animatiom
---@field new fun(frames: windui.Animation.Frame[]): windui.Animation
local Animation = {}
class(Animation, function(C)
  C.public()
  Animation.frames = nil

  ---@param frames windui.Animation.Frame[]
  function Animation:__init(frames)
    self.frames = frames
  end

  ---create animation with same {time} and {fps} every frame in {frames}
  ---@param time? integer
  ---@param fps? integer
  ---@param frames ({ time?: integer, fps?: integer, frame: windui.WindowState }|windui.WindowState)[]
  ---@return windui.Animation
  function Animation.with(time, fps, frames)
    local o = { frames = {} }
    setmetatable(o, {
      __index = Animation,
    })
    o.frames = vim.tbl_map(function(value)
      return {
        time = time or value.time or 0,
        fps = fps or value.fps or 0,
        frame = value.frame or value
      }
    end, frames)
    return o
  end

  ---play animation on {win}
  ---@param comp windui.Component
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

  function Animation:reverse()
    local frames = {}
    for i = #self.frames, 1, -1 do
      table.insert(frames, self.frames[i])
    end
    local anim = Animation.new(frames)
    return anim
  end

  ---set all frame time to equal {time} if summed
  ---@param time any
  function Animation:set_duration(time)
    local duration = time / #self.frames
    return Animation.with(duration, nil, self.frames)
  end
end)

return Animation
