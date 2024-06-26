local M = {}

---get border paart
---@param border windui.border
---@return string[]
function M.get_border_parts(border)
  if border == nil or border == "none" or border == "shadow" or #border == 0 then return { '', '', '', '', '', '', '', '' } end
  local chars = {}
  if type(border) == "string" then
    chars = ({
      single =    { '┌', '─', '┐', '│', '┘', '─', '└', '│' },
      double =    { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
      rounded =   { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
      solid =     { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' },
    })[border]
  else
    local parts = {}
    for i, part in ipairs(border) do
      if type(part) == "string" then
        parts[i] = part
      else
        parts[i] = part[1]
      end
    end

    local i = 1
    local len = 0
    while len < 8 do
      table.insert(chars, parts[i])
      i = i + 1
      if i > #parts then
        i = 1
      end
      len = len + 1
    end
  end
  return chars
end

---@alias windui.padding { top: integer, right: integer, bottom: integer, left: integer }

---make a padding for ui option
---@param top integer?
---@param right integer?
---@param left integer?
---@param bottom integer?
---@return windui.padding
function M.padding(top, right, left, bottom)
  local pad = {top, right, left, bottom}
  if #pad == 1 and top then
    return { top = top, right = top, bottom = top, left = top }
  elseif #pad == 2 and top and right then
    return { top = top, right = right, bottom = top, left = right }
  else
    return { top = top or 0, right = right or 0, bottom = bottom or 0, left = left or 0 }
  end
end

return M
