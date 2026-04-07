require('zenroom_common')

local uu = require'crypto_ulid'

TIME_NOW_OVERRIDE = '0'
local ulid = uu.ulid()
assert(#ulid == 26)
assert(string.match(ulid, '^[0-9A-HJKMNP-TV-Z]+$'))
local uuid_v1 = uu.uuid_v1()
assert(#uuid_v1 == 36)
assert(uuid_v1:sub(15, 15) == '1')
assert(string.find('89ab', uuid_v1:sub(20, 20), 1, true) ~= nil)
TIME_NOW_OVERRIDE = nil

print('ulid time regressions OK')
