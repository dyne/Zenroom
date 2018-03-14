print("-- Schema test");
user = {
   id        = 12, -- id is a number
   usertype  = "admin", -- one of 'admin', 'moderator', 'user'
   nicknames = { "Nick1", "Nick2" }, -- nicknames used by this user
   rights    = { 4, 1, 7 } -- table of fixed length of types
}

s = schema_validation()

rights = s.AllOf(s.NumberFrom(0, 7), s.Integer)

userSchema = s.Record {
   id        = s.Number,
   usertype  = s.OneOf("admin", "moderator", "user"),
   nicknames = s.Collection(s.String),
   rights    = s.Tuple(rights, rights, rights) 
}

local err = s.CheckSchema(user, userSchema)

-- 'err' is nil if no error occured
if err then
   print(s.FormatOutput(err))
end

user2 = {
   id        = "notanumber", -- id should be a number
   usertype  = "user", -- one of 'admin', 'moderator', 'user'
   nicknames = { "Nick1", "Nick2", "Nick3" }, -- nicknames used by this user
   rights    = { 4, 1, 7, 23 } -- table of fixed length of types
}

local err2 = s.CheckSchema(user2, userSchema)

assert(err2)
print("-- Schema test passed - OK")
