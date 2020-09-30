--#############################################################################
--# Parser
--#############################################################################
local utils = require("plugin.sqlightning.utils")

local _M = {}

function _M.whereTable(tbl)
  if utils.isTbl(tbl) then
    local str = {}
    local condition, field_parts, orig_field_name
    for field_name, value in pairs(tbl) do

      condition = nil

      if utils.isStr(value) then
        value = utils.quote(value)
      end

      orig_field_name = field_name

      field_parts = utils.split(field_name, "_")
      if #field_parts > 1 then
        condition = table.remove(field_parts, 1, 1)
      end

      if condition then

        field_name = utils.split(field_name, "_")
        table.remove(field_name, 1, 1)
        field_name = table.concat(field_name, "_")

        print(condition)

        if condition == "AND" then
          table.insert(str, ('AND '..field_name.."="..value))
        elseif condition == "ANDLT" then
          table.insert(str, ('AND '..field_name.."<"..value))
        elseif condition == "ANDLTE" then
          table.insert(str, ('AND '..field_name.."<="..value))
        elseif condition == "ANDGT" then
          table.insert(str, ('AND '..field_name..">"..value))
        elseif condition == "ANDGTE" then
          table.insert(str, ('AND '..field_name..">="..value))
        elseif condition == "OR" then
          table.insert(str, ('OR '..field_name.."="..value))
        elseif condition == "ORLT" then
          table.insert(str, ('OR '..field_name.."<"..value))
        elseif condition == "ORLTE" then
          table.insert(str, ('OR '..field_name.."<="..value))
        elseif condition == "ORGT" then
          table.insert(str, ('OR '..field_name..">"..value))
        elseif condition == "ORGTE" then
          table.insert(str, ('OR '..field_name..">="..value))
        elseif condition == "LT" then
          table.insert(str, (field_name.."<"..value))
        elseif condition == "LTE" then
          table.insert(str, (field_name.."<="..value))
        elseif condition == "GT" then
          table.insert(str, (field_name..">"..value))
        elseif condition == "GTE" then
          table.insert(str, (field_name..">="..value))
        else
          table.insert(str, ('AND '..(orig_field_name.."="..value)))
        end
      else
        if #str < 1 then
          table.insert(str, (orig_field_name.."="..value))
        else
          table.insert(str, ('AND '..orig_field_name.."="..value))
        end
      end
    end

    return table.concat(str, " ")
  else
    return nil, "table 'where' not found."
  end
end

function _M.limitTable(tbl)
  if utils.isTbl(tbl) or utils.isNum(tbl) then
    local limitStr
    if utils.isTbl(tbl) then
      limit = tbl[1]
      offset = tbl[2]

      limitStr = limit .." OFFSET "..offset
    else
      limitStr = tostring(tbl)
    end

    return limitStr
  else
    return nil, "table 'limit' not found."
  end
end

function _M.orderbyTable(tbl)
  if utils.isTbl(tbl) then
    local orderStr = {}
    for col, order in pairs(tbl) do
      table.insert(orderStr, (col.." ".. order))
    end

    return table.concat(orderStr, " ")
  else
    return nil, "table 'orderby' not found."
  end
end

function _M.columnsTable(tbl)
  if utils.isTbl(tbl) then
    local columnStr = {}
    for _, col in ipairs(tbl) do
      table.insert(columnStr, col)
    end

    return table.concat(columnStr, ", ")
  else
    return nil, "table 'columns' not found."
  end

end

function _M.valuesTable(tbl)
  if utils.isTbl(tbl) then
    local columns = {"id"}
    local values = {}
  
    for name, value in pairs(tbl) do
      if utils.isStr(value) then
        table.insert(values, utils.quote(value, true))
      else
        table.insert(values, value)
      end
  
      table.insert(columns, name)
    end

    local colStr = table.concat(columns, ", ")
    local valStr = table.concat(values, ", ")

    return colStr, valStr
  else
    return nil, "table 'values' not found."
  end
end

function _M.updateTable(tbl)
  if utils.isTbl(tbl) then
    local str = {}

    for name, value in pairs(tbl) do
      if type(value) == "string" then
        table.insert(str, name .. "=" .. utils.quote(value))
      else
        table.insert(str, name .. "=" .. value)
      end
    end

    return table.concat(str, ", ")
  else
    return nil, "table 'set' not found."
  end
end

function _M.createDbTable(tbl)
  local valuesTbl = {}

  local tStr

  for name, value in pairs(tbl) do
    tStr = {}

    -- field type/options
    for _, v in ipairs(value) do
      table.insert(tStr, v)
    end

    tStr = table.concat(tStr, " ")
    tStr = utils.join(" ", utils.quote(name, true), tStr)

    table.insert(valuesTbl, tStr)

  end

  return table.concat(valuesTbl, ", ")
end

return _M