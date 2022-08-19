-- CONF.output.encoding = get_encoding('url64')
-- test zero
zero = INT.new(0)
one  = INT.new(1)
two  = INT.new(2)
four = INT.new(4)

assert(zero + zero == zero, "Error zero sum")
assert(one + one   == two, "Error one plus one")
assert(one + zero  == one, "Error one plus zero")

assert(two * two == four, "Error two times two")
assert(two - one == one, "Error two minus one")

assert(four / two == two, "Error four divided by two")

assert(four:int() == 4, "Error four conversion to int")
-- /* maximum length of the conversion of a number to a string */
-- #define MAXNUMBER2STR	50


assert(BIG.new(O.from_hex('0a')):int() == 10, "Octet -> BIG -> integer conversion failed")
assert(BIG.new(O.from_hex('14')):int() == 20, "Octet -> BIG -> integer conversion failed")
