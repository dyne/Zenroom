print("-- Schema test");
user = {
   id        = 12, -- id is a number
   usertype  = "admin", -- one of 'admin', 'moderator', 'user'
   nicknames = { "Nick1", "Nick2" }, -- nicknames used by this user
   rights    = { 4, 1, 7 } -- table of fixed length of types
}

-- s = require "schema"

rights = schema.AllOf(schema.NumberFrom(0, 7), schema.Integer)

userSchema = schema.Record {
   id        = schema.Number,
   usertype  = schema.OneOf("admin", "moderator", "user"),
   nicknames = schema.Collection(schema.String),
   rights    = schema.Tuple(rights, rights, rights) 
}

local err = schema.CheckSchema(user, userSchema)

-- 'err' is nil if no error occured
if err then
   print(schema.FormatOutput(err))
end

user2 = {
   id        = "notanumber", -- id should be a number
   usertype  = "user", -- one of 'admin', 'moderator', 'user'
   nicknames = { "Nick1", "Nick2", "Nick3" }, -- nicknames used by this user
   rights    = { 4, 1, 7, 23 } -- table of fixed length of types
}

local err2 = schema.CheckSchema(user2, userSchema)

assert(err2)
print("-- Schema test passed - OK")
