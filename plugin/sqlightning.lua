--#############################################################################
--# SQLightning
--# An SQLite plugin
--# (c)2020 C. Byerley
--#############################################################################
local sqlite = require("sqlite3")
local utils = require("plugin.sqlightning.utils")
local parse = require("plugin.sqlightning.parse")

local strf = string.format

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

--#############################################################################
--# Constants
--#############################################################################
local DB_TYPE = {
  FILE = "file",
  MEMORY = "memory"
}

--Data Types
_M.TEXT = "TEXT"
_M.INTEGER = "INTEGER"
_M.NUMERIC = "NUMERIC"
_M.REAL = "REAL"
_M.BLOB = "BLOB"

_M.UNIQUE = "UNIQUE"
_M.NOTNULL = "NOT NULL"

_M.ASC = "ASC"
_M.DESC = "DESC"

--#############################################################################
--# Privates
--#############################################################################


--#############################################################################
--# Constructor
--#############################################################################
function _M.new( options )
  if options and type(options) == "table" then
    --memory or file
    if not options.db_path then
      options.db_type = DB_TYPE.MEMORY
    else
      options.db_type = DB_TYPE.FILE
    end
  else
    options = {
      db_type = DB_TYPE.MEMORY,
      db_debug = false
    }
  end

  -- options = options or {
  --   _db = nil,
  --   db_path = nil,
  --   db_type = DB_TYPE.FILE,
  --   db_debug = false,
  -- }

  return setmetatable(options, mt)

end

--#############################################################################
--# Static
--#############################################################################
function _M.version()
  return _M._VERSION
end

--#############################################################################
--# Utils
--#############################################################################
function _M.debug( self, ... )
  if self.db_debug then
    local msg = {...}
    msg = table.concat(msg, ", ")
    print( msg )
  end
end

--#############################################################################
--# Methods
--#############################################################################
function _M.open( self )
  if not self._db then
    if self.db_type and self.db_type == DB_TYPE.MEMORY then
      self._db = sqlite.open_memory()
    else
      local path = system.pathForFile( self.db_path, system.DocumentsDirectory )
      self._db = sqlite.open( path )
    end
  end

  return self
end

function _M.close(self)
  self._db:close()
  self._db = nil
end

function _M.execute(self, query)
  self:open()

  self:debug( query )
  local res = self._db:exec( query )

  self:close()

  return res
end

function _M.createTable(self, tbl_name, fields)
  local q

  local valuesTbl = {}

  local tStr

  for name, value in pairs(fields) do
    tStr = {}

    for _, v in ipairs(value) do
      table.insert(tStr, v)
    end

    tStr = table.concat(tStr, " ")
    tStr = utils.join(" ", utils.quote(name, true), tStr)

    table.insert(valuesTbl, tStr)

  end

  valuesTbl = table.concat(valuesTbl, ", ")
  
  if tbl_name and fields then
    q = strf('CREATE TABLE IF NOT EXISTS %s ("id" INTEGER PRIMARY KEY, %s);', 
      tbl_name, 
      valuesTbl)
  else
    q = strf('CREATE TABLE IF NOT EXISTS %s ("id" INTEGER PRIMARY KEY);', tbl_name)
  end

  return self:execute( q )
end

function _M.add(self, data)

  if utils.isTbl(data) then
    local colStr, valStr = parse.valuesTable(data.values)

    local q = strf("INSERT INTO %s (%s) VALUES (NULL, %s);", data.tbl, colStr, valStr)

    return self:execute( q )
  else
    return nil, "table 'values' not found."
  end

  return nil, "could not add record."
end

function _M.addMany(self, tbl_name, entries)

end

function _M.get(self, tbl_name, query)
  self:open()

  local rows = {}

  --fields and values
  local qBuilder = {}

  if query.columns then
    table.insert(qBuilder, strf("SELECT %s FROM %s", parse.columnsTable(query.columns), tbl_name))
  else
    table.insert(qBuilder, strf("SELECT * FROM %s", tbl_name))   
  end

  if query.where then
    table.insert(qBuilder, strf("WHERE %s", parse.whereTable(query.where)))
  end

  if query.orderby then
    table.insert(qBuilder, strf("ORDER BY %s", parse.orderbyTable(query.orderby)))
  end

  if query.limit then
    table.insert(qBuilder, strf("LIMIT %s", parse.limitTable(query.limit)))
  end

  local q = table.concat(qBuilder, " ") .. ";"

  self:debug( q )

  for row in self._db:nrows( q ) do
    table.insert(rows, row)
  end

  self:close()

  return rows, #rows

end

function _M.getAll(self, tbl_name)
  self:open()

  local rows = {}

  local q = strf("SELECT * FROM %s;", tbl_name)

  self:debug( q )

  for row in self._db:nrows( q ) do
    table.insert(rows, row)
  end

  self:close()

  return rows, #rows
end

function _M.getOne(self, tbl_name, query)
  query.limit = 1
  local rows = self:get(tbl_name, query)

  if #rows > 0 then
    return rows[1]
  end

  return nil
end

function _M.getById(self, tbl_name, id)
  local row = self:getOne(tbl_name, {
    where = { id = id }
  })

  return row
end

function _M.update(self, tbl_name, query)
  local qBuilder = {}

  table.insert(qBuilder, strf("UPDATE %s", tbl_name))

  if query.values then
    table.insert(qBuilder, strf("SET %s", parse.updateTable(query.values)))  
  end

  if query.where then
    table.insert(qBuilder, strf("WHERE %s", parse.whereTable(query.where)))
  end

  if query.orderby then
    table.insert(qBuilder, strf("ORDER BY %s", parse.orderbyTable(query.orderby)))
  end

  if query.limit then
    table.insert(qBuilder, strf("LIMIT %s", parse.limitTable(query.limit)))
  end

  return self:execute( table.concat(qBuilder, " ") .. ";" )

end

function _M.updateById(self, tbl_name, id, query)

end

function _M.delete(self, tbl_name, query)
  local qBuilder = {}

  table.insert(qBuilder, strf("DELETE FROM %s", tbl_name))

  if query.where then
    table.insert(qBuilder, strf("WHERE %s", parse.whereTable(query.where)))
  end

  return self:execute( table.concat(qBuilder, " ") .. ";" )
end

function _M.deleteLike(self, tbl_name, column, value)
  local q = strf("DELETE FROM %s WHERE '%s' LIKE '%%%s%%';", tbl_name, column, value)
  return self:execute( q )
end

function _M.deleteAll(self, tbl_name)
  return self:execute( strf('DELETE FROM %s;', tbl_name) )
end

function _M.query(self, query_str)
  self:open()

  local rows = {}

  local q = query_str

  self:debug( q )

  for row in self._db:nrows( q ) do
    table.insert(rows, row)
  end

  self:close()

  return rows, #rows
end


--#############################################################################
--# Events
--#############################################################################
-- local function onSystemEvent( event )
--   if ( event.type == "applicationExit" ) then
--     self._db:close()
--   end
-- end

-- Runtime:addEventListener( "system", onSystemEvent )

--#############################################################################
--# Export
--#############################################################################
return _M