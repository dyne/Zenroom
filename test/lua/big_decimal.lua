-- Tests for big from decimal
assert(BIG.from_decimal('0'):octet() == O.from_hex('00'))
assert(BIG.from_decimal('1'):octet() == O.from_hex('01'))
assert(BIG.from_decimal('10000'):octet() == O.from_hex('2710'))
assert(BIG.from_decimal('3241234123454677858658653465435'):octet() == O.from_hex('28e8fe07152f8191d2f12e6b5b') )
assert(BIG.from_decimal('908907679878905720234758926590204765297843'):octet() == O.from_hex('0a6f0a23bc79a6a46e27428337f35fbc5cb3'))

-- Tests for big to decimal
assert(BIG.from_decimal('0'):decimal() == '0')

assert(BIG.from_decimal('1'):decimal() == '1')
assert(BIG.from_decimal('99'):decimal() == '99')

assert(BIG.from_decimal('10000000'):decimal() == '10000000')

local num = "123456789"
assert(BIG.from_decimal(num):decimal() == num)

local num = "123456789123456789"
assert(BIG.from_decimal(num):decimal() == num)

local num = "12345678912345678912345"
assert(BIG.from_decimal(num):decimal() == num)

local num = "123456789123456789123456"
assert(BIG.from_decimal(num):decimal() == num)

local num = "123456789123456789123456789"
assert(BIG.from_decimal(num):decimal() == num)

local num = "4590989214817463456238493812468796952385932489143279876421643219463"
assert(BIG.from_decimal(num):decimal() == num)
