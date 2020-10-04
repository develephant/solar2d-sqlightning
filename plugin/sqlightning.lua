--#############################################################################
--# SQLightning
--# An SQLite plugin
--# (c)2020 C. Byerley
--#############################################################################
local sqlite = require("sqlite3")
local utils = require("lib.sqlightning.utils")
local parse = require("lib.sqlightning.parse")

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

  if tbl_name and fields then
    q = strf('CREATE TABLE IF NOT EXISTS %s ("id" INTEGER PRIMARY KEY, %s);', 
      tbl_name, 
      parse.createDbTable(fields))
  else
    q = strf('CREATE TABLE IF NOT EXISTS %s ("id" INTEGER PRIMARY KEY);', tbl_name)
  end

  return self:execute( q )
end

function _M.query(self, query_str)
  local rows = {}

  self:open()
  self:debug( query_str )

  for row in self._db:nrows( query_str ) do
    table.insert(rows, row)
  end

  self:close()

  return rows, #rows
end

--#############################################################################
--# ADD
--#############################################################################
function _M.add(self, tbl_name, values)
  if utils.isTbl(values) then
    local colStr, valStr = parse.valuesTable(values)
    return self:execute( strf("INSERT INTO %s (%s) VALUES (NULL, %s);", tbl_name, colStr, valStr) )
  else
    return nil, "table 'values' not found."
  end

  return nil, "could not add record."
end

function _M.addMany(self, tbl_name, records)
  if utils.isTbl(records) then
    self:open()
    
    local colStr, valStr
    for rec=1, #records do
      colStr, valStr = parse.valuesTable(records[rec])
      self._db:exec( strf("INSERT INTO %s (%s) VALUES (NULL, %s);", tbl_name, colStr, valStr) )
    end

    self:close()
  else
    return nil, "table 'records' not found."
  end

  return nil, "method 'addMany' failed."
end

--#############################################################################
--# GET
--#############################################################################
function _M.get(self, tbl_name, query)
  local rows = {}
  local qBuilder = {}

  self:open()

  --fields and values
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
  local rows = {}

  self:open()

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

--#############################################################################
--# UPDATE
--#############################################################################
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

--#############################################################################
--# DELETE
--#############################################################################
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

--#############################################################################
--# Utils
--#############################################################################
function _M.count(self, tbl_name)
  local rows = self:query( strf("SELECT COUNT(id) AS cnt FROM %s;", tbl_name) )
  return rows[1].cnt
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