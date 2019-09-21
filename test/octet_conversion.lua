print '================================'
print 'TEST OCTET CONVERSIONS (12 bytes)'
msg_str = 'Hello world!'
msg_hex = '48656c6c6f20776f726c6421'
msg_hex_sp = '48 65 6c 6c 6f 20 77 6f 72 6c 64 21'
msg_b64 = 'SGVsbG8gd29ybGQh'
msg_u64 = 'SGVsbG8gd29ybGQh'
OK = O.from_hex(msg_hex) -- most solid import
assert(msg_hex:lower() == OK:hex(), 'fail in hex import')
assert(OK:str() == msg_str, 'fail in string export')
assert(O.from_string(msg_str) == OK, 'fail in string import')
assert(O.from_base64(msg_b64) == OK, 'fail in base64 import')
assert(O.from_url64(msg_u64) == OK, 'fail in url64 import')


print '================================'
print 'TEST OCTET CONVERSIONS (8 bytes)'
-- vectors from https://www.di-mgt.com.au/cryptoCipherText.html
msg_bin = '1111111011011100101110101001100001110110010101000011001000010000'
msg_bin_sp = [[
11111110 11011100 10111010 10011000 
01110110 01010100 00110010 00010000
]]
msg_hex = 'FEDCBA9876543210'
msg_hex_sp = 'FE DC BA 98 76 54 32 10'
msg_b64 = "/ty6mHZUMhA="
msg_u64 = "_ty6mHZUMhA"
OK = O.from_hex(msg_hex) -- most solid import
-- print(OK:bin() ..  " <- hex")
-- print(O.from_url64(msg_u64):bin() .. " <- url64")
-- print(O.from_base64(msg_b64):bin() .. " <- base64")
assert(msg_hex:lower() == OK:hex(), 'fail in hex import')
assert(O.from_url64(msg_u64) == OK, 'fail in url64 import')
assert(O.from_base64(msg_b64) == OK, 'fail in base64 import')
assert(O.from_bin(msg_bin) == OK, 'fail in bin import')
assert(O.from_bin(msg_bin_sp) == OK, 'fail in bin / space import')

