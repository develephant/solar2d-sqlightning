# SQLightning

```lua
local sl = require("plugin.sqlightning")
```

## Constructor

### .new( [options_tbl] )

_Creates a new database instance. If `dp_path` is omitted (or no options table is passed), the database will be created in-memory._

__Example:__

```lua
-- FILE BASED
local db = sl.new({ db_path = "my.db" })
-- MEMORY BASED
local db = sl.new()
```

__Options Table:__

|parameter|type|description|
|---------|----|-----------|
|`db_path`|string|The path to the database file relative to the Documents directory.|
|`db_debug`|boolean|Output all queries to the console window.|

### .version

_Returns the current version of `SQLightning`._

__Example:__

```lua
print( db.version() )
```

---

## Methods

### :add( query_tbl )

__Example:__

```lua
local err = db:add({
  tbl = "cats",
  values = {
    name = "Tribble",
    age = 5
  }
})
```

### :addMany( table_name, records_tbl )

_Adds multiple records to a database table._

__Example:__

```lua
local cat_records = {
  {
    name = "Spiffy",
    age = 2
  },
  {
    name = "Ginger",
    age = 5
  }
}

local err = db:addMany("cats", cat_records)
```

### :createTable( table_name, values_tbl )

_Create a new database table with fields and types._

__Example:__

```lua
local err = db:createTable("cats", {
  name = {db.TEXT, db.UNIQUE},
  color = {db.TEXT},
  age = {db.INTEGER}
})
```

### :delete( table_name, query_tbl )

__Example:__

```lua
local err = db:delete("cats", {
  where = { age = 2 }
})
```

### :deleteAll( table_name )

_Deletes all records in a database leaving an empty database table._

__Example:__

```lua
local err = db:deleteAll("cats")
```

### :deleteLike( table_name, field, value )

_Run a delete query using the LIKE modifier._

__Example:__

```lua
local err = db:deleteLike("cats", "color", "blue")
```

### :get( table_name, query_tbl )

_Return a set of records from a database table. Records are contained in a table based array._

__Example:__

```lua
local rows, err = db:get("cats", {
  where = { age = 2 },
  orderby = {
    color = db.DESC
  }
})

--Outputting
for row in rows do
  print(row.color)
end
```

### :getAll( table_name )

_Retrieve the entire record set from a database table._

__Example:__

```lua
local rows, err = db:getAll("cats")
```

### :getOne( table_name, query_tbl )

_Retuns a single record. Thie result is a single row object, and is not contained in a table array._

__Example:__

```lua
local row, err = db:getOne("cats", {
  where = { age = 2 }
})

--Outputting
print( row.color )
```

### :getById( table_name, id )

_Return a single row using an `id`._

__Example:__

```lua
local row, err = db:getById("cats", 3)

--Outputting
print( row.color )
```

### :update( table_name, query_tbl )

__Example:__

```lua
local err = db:update("cats", {
  where = { id = 1 },
  values = {
    age = 5
  }
})
```

### :updateById

### :query( query_string )

_Run a raw query on the database table._

__Example:__

```lua
local res, err = db:query("SELECT * FROM cats;")
```

## CONSTANTS

 - db.TEXT 
 - db.INTEGER
 - db.NUMERIC
 - db.REAL
 - db.BLOB
 - db.UNIQUE
 - db.NOTNULL
 - db.ASC
 - db.DESC

## WHERE Field Modifiers

The AND modifier is used by default when no modifier is added.

__Example:__

```lua
{
  where = { color = "Green", ANDLT_age = 3 }
  --> WHERE color='Green' AND age<3
}
```

__Can NOT be used on first `where` table entry__

 - AND_*
 - ANDLT_*
 - ANDLTE_*
 - ANDGT_*
 - ANDGTE_*


 - OR_*
 - ORLT_*
 - ORLTE_*
 - ORGT_*
 - ORGTE_*

__Can ONLY be used on first `where` table entry__

 - LT_*
 - LTE_*
 - GT_*
 - GTE_*

 ```lua
-- !! NO - Use ANDLT_* or ORLT_* on second entry. !!
{
  where = { color = "blue", LT_age = 2 }
}

-- ** YES - Use LT_*, LTE_*, GT_*, or GTE_* on first entry. **
{
  where = { LT_age = 2, OR_color = "blue" }
}
--> WHERE age<2 OR color='blue'
 ```

 ## The Query Table

 _Not all fields may be applicable for each method. See method docs for usage._

|parameter|type|description|
|---------|----|-----------|
|`where`|table|desc|
|`orderby`|table|desc|
|`limit`|number or table|desc|
|`columns`|table|desc|
|`values`|table|desc|



