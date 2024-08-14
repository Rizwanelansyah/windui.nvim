---@diagnostic disable: redefined-local
---@class classic.Class
---@field new fun(): self

---@class classic.class_config
---@field public public fun(): classic.class_config
---@field public private fun(): classic.class_config
---@field public static fun(): classic.class_config
---@field public field fun(): classic.class_config
local class_config = {}
local visibility = { on = '__field', mod = '__private' }
local special_method = {
  __init = true,
  __call = true,
  __get = true,
  __set = true,
}
local null = {}
local class_match = require('classic.match')

local match = {}
function match.public()
  visibility.mod = '__public'
  return match
end

function match.private()
  visibility.mod = '__private'
  return match
end

function match.static()
  visibility.on = '__static'
  return match
end

function match.field()
  visibility.on = '__field'
  return match
end

setmetatable(class_config, {
  __index = function(_, k)
    return match[k]
  end
})

local function ternary(condition, true_v, false_v)
  if condition then
    return true_v
  else
    return false_v
  end
end

local function _or(v1, v2)
  return ternary(v1 ~= nil, v1, v2)
end

local function conv(v)
  if v ~= null then return v end
end

local function do_in(t, func, ...)
  local meta = getmetatable(t)
  local in_class = meta.__in_class
  if not in_class then meta.__in_class = true end
  local res = func(...)
  if not in_class then meta.__in_class = false end
  return res
end

local function make_do_in(t, func)
  return function(...)
    return do_in(t, func, ...)
  end
end

local function self_index(class, self, key)
  local meta = getmetatable(class)
  local self_meta = getmetatable(self)
  local res

  if self_meta.__in_class then
    res = meta.__field.__private[key]
    if type(res) == "function" then return res end
    if res ~= nil then return _or(self_meta.__real_value[key], conv(res)) end
  end

  res = meta.__field.__public[key]
  if type(res) == "function" then return res end
  if res ~= nil then return _or(self_meta.__real_value[key], conv(res)) end

  if meta.__parent then
    return self_index(meta.__parent, self, key)
  end
end

local function self_newindex(class, self, key, value)
  local meta = getmetatable(class)
  local self_meta = getmetatable(self)
  local res

  if self_meta.__in_class then
    res = meta.__field.__private[key]
    if type(res) == "function" then
      error("cannot reassign method")
    end
    if res ~= nil then
      self_meta.__real_value[key] = value
      return
    end
  end

  res = meta.__field.__public[key]
  if type(res) == "function" then
    error("cannot assign to method '" .. key .. "'")
  end
  if res ~= nil then
    self_meta.__real_value[key] = value
    return
  end

  if meta.__parent then
    return self_newindex(meta.__parent, self, key, value)
  end
end

local function new(class, ...)
  local self = {}
  local meta = {
    __class = class,
    __in_class = false,
    __real_value = {},
  }

  function meta.__index(self, key)
    return self_index(class, self, key)
  end

  function meta.__newindex(self, key, value)
    return self_newindex(class, self, key, value)
  end

  setmetatable(self, meta)

  local init = getmetatable(class).__field.__public.__init
  if type(init) == "function" then
    init(self, ...)
  end

  return self
end

local function class_newindex(as_class, class, key, value)
  local meta = getmetatable(as_class) or {}
  local orig_meta = getmetatable(class) or {}

  if not orig_meta.__locked then
    if type(value) == "function" then
      local func
      if visibility.on == '__field' or special_method[key] then
        func = function(...)
          local in_classes = {}
          for i, self in ipairs { ... } do
            local meta = getmetatable(self or {}) or {}
            if class_match(meta.__class, class) then
              in_classes[i] = meta.__in_class
              if not in_classes[i] then meta.__in_class = true end
            end
          end

          local res = value(...)

          for i, self in ipairs { ... } do
            local meta = getmetatable(self or {}) or {}
            if class_match(meta.__class, class) then
              if not in_classes[i] then meta.__in_class = false end
            end
          end
          return res
        end
      else
        func = value
      end
      func = make_do_in(class, func)
      local parent = orig_meta.__parent
      while parent do
        func = make_do_in(parent, func)
        parent = getmetatable(parent).__parent
      end
      orig_meta[ternary(special_method[key], '__field', visibility.on)][ternary(special_method[key], '__public', visibility.mod)][key] =
          func
    else
      meta[visibility.on][visibility.mod][key] = _or(value, null)
    end
    return
  end

  local res
  if meta.__in_class then
    res = meta.__static.__private[key]
    if res ~= nil then
      orig_meta.__real_value[key] = value
      return
    end
  end

  res = meta.__static.__public[key]
  if res ~= nil then
    orig_meta.__real_value[key] = value
    return
  end

  if meta.__parent then
    return class_newindex(meta.__parent, class, key, value)
  end
end

local function class_index(as_class, class, key)
  local meta = getmetatable(as_class)
  local orig_meta = getmetatable(class)
  if key == 'new' then
    return function(...)
      return new(class, ...)
    end
  end

  local res
  if meta.__in_class then
    res = meta.__field.__private[key]
    if type(res) == "function" then return res end

    res = meta.__static.__private[key]
    if type(res) == "function" then return res end
    if res ~= nil then return orig_meta.__real_value[key] or conv(res) end
  end

  res = meta.__field.__public[key]
  if type(res) == "function" then return res end

  res = meta.__static.__public[key]
  if type(res) == "function" then return res end
  if res ~= nil then return orig_meta.__real_value[key] or conv(res) end

  if meta.__parent then
    return class_index(meta.__parent, class, key)
  end
end

---create a new class on {c}
---this function doesn't return any value
---this function modify {c} as class
---@param c {} #must be an empty table
---@param func? classic.Class | fun(V: classic.class_config) #class constructor or parent class
---@param func2? fun(V: classic.class_config) #class constructor if {func} is parent class
local function make_class(c, func, func2)
  visibility.on = '__field'
  visibility.mod = '__private'
  local meta = {
    __field = {
      __public = {},
      __private = {},
    },
    __static = {
      __public = {},
      __private = {},
    },
    __real_value = {},
    __in_class = false,
    __locked = false,
  }

  if type(func) == "table" then
    meta.__parent = func
  end

  function meta.__newindex(class, key, value)
    return class_newindex(class, class, key, value)
  end

  function meta.__index(class, key)
    return class_index(class, class, key)
  end

  setmetatable(c, meta)
  if type(func) == "table" then
    if func2 then
      func2(class_config)
    end
  else
    if func then
      func(class_config)
    end
  end
  meta.__locked = true
end

return make_class
