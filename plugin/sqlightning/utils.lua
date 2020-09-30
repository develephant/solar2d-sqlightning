--#############################################################################
--# Utils
--#############################################################################
local _M = {}

function _M.isTbl(tbl)
  if tbl and type(tbl) == "table" then
    return true
  end

  return false
end

function _M.isStr(str)
  if str and type(str) == "string" then
    return true
  end

  return false
end

function _M.isNum(num)
  if num and type(num) == "number" then
    return true
  end

  return false
end

function _M.isBool(bool)
  if bool and type(bool) == "boolean" then
    return true
  end

  return false
end

function _M.join(sep, ...)
  parts = {...}
  parts = table.concat(parts, sep)
  return parts
end

function _M.split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={} ; local i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

function _M.quote(value, asDouble)
  if asDouble then
    return '"'..value..'"'
  end

  return "'"..value.."'"
end

return _M