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

print('----------------------------------------------')

-- MODULAR ARITHMETICS TESTS

print("TEST: Tonelli-Shanks")

-- case p = 3 mod 4 
local p = ECP.prime()
for i = 1, 10 do
    print("Test case ".. i)
    local res = BIG.modrand(p)
    local n = BIG.modsqr(res, p)
    local r = BIG.modsqrt(n, p)
    assert((r == res) or (r == BIG.modneg(res, p)))
end
--case p = 1 mod 4
p = BIG.new(O.from_hex('1000000000000021'))
for i = 11, 20 do
    print("Test case ".. i)
    local res = BIG.modrand(p)
    local n = BIG.modsqr(res, p)
    local r = BIG.modsqrt(n, p)
    assert((r == res) or (r == BIG.modneg(res, p)))
end

--[[
print("Test failure")
local n = BIG.modrand(p)
while BIG.jacobi(n,p) == 1 do
    n = BIG.modrand(p)
end
local r = BIG.modsqrt(n,p)
--]]
