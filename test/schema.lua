print("-- Schema test");
user = {
   id        = 12, -- id is a number
   usertype  = "admin", -- one of 'admin', 'moderator', 'user'
   nicknames = { "Nick1", "Nick2" }, -- nicknames used by this user
   rights    = { 4, 1, 7 } -- table of fixed length of types
}

-- s = require "schema"

rights = SCHEMA.AllOf(SCHEMA.NumberFrom(0, 7), SCHEMA.Integer)

userSchema = SCHEMA.Record {
   id        = SCHEMA.Number,
   usertype  = SCHEMA.OneOf("admin", "moderator", "user"),
   nicknames = SCHEMA.Collection(SCHEMA.String),
   rights    = SCHEMA.Tuple(rights, rights, rights) 
}

local err = SCHEMA.CheckSchema(user, userSchema)

-- 'err' is nil if no error occured
if err then
   print(SCHEMA.FormatOutput(err))
end

user2 = {
   id        = "notanumber", -- id should be a number
   usertype  = "user", -- one of 'admin', 'moderator', 'user'
   nicknames = { "Nick1", "Nick2", "Nick3" }, -- nicknames used by this user
   rights    = { 4, 1, 7, 23 } -- table of fixed length of types
}

local err2 = SCHEMA.CheckSchema(user2, userSchema)

assert(err2)
print("-- Schema test passed - OK")
