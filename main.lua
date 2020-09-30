--#############################################################################
--# SQLightning Harness
--#############################################################################
local strf = string.format

local sl = require("plugin.sqlightning")

print(sl.version())

local db = sl.new({ db_path = "chumbyland.db", db_debug = true })

local row, err = db:get("chums", {
  where = { chum_id = "chum_006", age = 2 }
})
-- print(row.icon)
-- local db = sl.new({ db_path = "my.db", db_debug = true })

-- db:createTable("cats", {
--   name = {db.TEXT, db.UNIQUE},
--   color = {db.TEXT},
--   age = {db.INTEGER}
-- })

-- local res = db:add({
--   tbl = "cats",
--   values = {
--     name = "Tribble",
--     color = "Orange",
--     age = 7
--   }
-- })

-- print(res)

-- local res = db:update("cats", {
--   values = { color = "Green" },
--   where = { 
--     id = 1,
--     OR_last_name = "Timmy",
--     ORGT_age = 3
--   }
-- })

-- local rows = db:getAll("cats")

-- local rows, cnt = db:get("cats", {
--   orderby = {
--     color = db.ASC
--   },
--   limit = 1
-- })

-- local row = db:getOne("cats", {
--   where = { color = "Blue" }
-- })

-- print(row.color)

-- for idx, row in ipairs(rows) do
--   print(row.color)
-- end

-- print("rows: "..cnt)

-- local row = db:getById("cats", 1)

-- print(row.color)

-- local res = db:delete("cats", {
--   where = { color = "Sandy" }
-- })

-- local res = db:deleteLike("cats", "name", "Blue")

-- print(res)