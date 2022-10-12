-- Tests from https://homes.esat.kuleuven.be/~bosselae/ripemd160.html

H=HASH.new('ripemd160')

assert(H:process(O.empty()) == O.from_hex('9c1185a5c5e9fc54612808977ee8f548b2258d31'))
assert(H:process('a') == O.from_hex('0bdc9d2d256b3ee9daae347be6f4dc835a467ffe'))
assert(H:process('abc') == O.from_hex('8eb208f7e05d987a9b044a8e98c6b087f15a0bfc'))
assert(H:process('message digest') == O.from_hex('5d0689ef49d2fae572b881b123a85ffa21595f36'))
assert(H:process('abcdefghijklmnopqrstuvwxyz') == O.from_hex('f71c27109c692c1b56bbdceb5b9d2865b3708dbc'))
assert(H:process('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq') == O.from_hex('12a053384a9c0c88e405a06c27dcf49ada62eb2b'))
assert(H:process('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') == O.from_hex('b0e20b6e3116640286ed3a87a5713079b21f5189'))
assert(H:process('12345678901234567890123456789012345678901234567890123456789012345678901234567890') == O.from_hex('9b752e45573d4b39f4dbd3323cab82bf63326bfb'))
local msg_million_a = O.zero(1000000)
msg_million_a:fill(O.from_str('a'))
assert(H:process(msg_million_a) == O.from_hex('52783243c1697bdbe16d37f97f68f08325dc1528'))
