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

-- "Hello World"
hello = {
   base64 = "SGVsbG8gV29ybGQ=",
   base58 = "JxF12TrwUP45BMd",
   hex = "48656c6c6f20576f726c64",
   bin = "0100100001100101011011000110110001101111001000000101011101101111011100100110110001100100"
}
helloSchema = S.Record {
   base64 = S.base64,
   base58 = S.base58,
   hex = S.hex,
   bin = S.bin }

local err = S.CheckSchema(hello,helloSchema)
if err then
   print(S.FormatOutput(err))
end

print("-- Schema test passed - OK")
