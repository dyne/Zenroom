local FS = require'fiat_shamir'

print("TEST VECTORS from Frigo's RFC")

tr_1 = O.from_string("test")
len_1 = O.from_number(tr_1:__len()):reverse():sub(1,8)
zero = O.from_hex('00')
transcript_1 = zero:__concat(len_1):__concat(tr_1)
result_1 = FS.fiat_shamir(transcript_1,20,0):hex()
assert(result_1 == "ca44c5bc2d395c8b88a28891ccaa05b447ba00dc", "FS.fiat_shmair() doesn't return the expected stream")
print("OK: generation of stream")

m = big.from_decimal("1000000000")
result_2 = FS.generate_nat(m,transcript_1,0)
assert(result_2:decimal() == "190593325", "FS.generate_nat() doesn't return the expected random number")
print("OK: generation of a random number")

local function test_bytes(transcript)
    --check that no bit is stuck at 0 or 1.
    local N = 100
    local buf = FS.fiat_shamir(transcript,N,0)
    local band = O.from_hex("ff")
    local bor = O.from_hex("00")
    for i = 1, N do 
        band = band:__band(buf:sub(i,i))
        bor = bor:__bor(buf:sub(i,i))
    end 
    assert(band == O.from_hex("00"), "NO RANDOM: a bit is always equal to 1")
    assert(bor == O.from_hex("ff"), "NO RANDOM: a bit is always equal to 0")
end 

test_bytes(transcript_1)
print("OK: test bytes")

local function mask(n)
    assert(type(n) == "zenroom.big", "m is not a BIG")
    local oct = O.new(n)
    local len = oct:__len()
    local mask = O.from_bin("0"):pad(len)
    local band = O.from_hex("01"):pad(len)
    while oct:__band(mask) ~= oct do
        mask = mask:__shl(1)
        mask = mask:__bor(band)
    end
    return mask
end


local function test_nat(transcript, ub)
    --check that no bit is stuck at 0 or 1.
    assert(type(ub) == "zenroom.big", "m is not a BIG")
    local N = 100
    local sub = big.zensub(ub,big.new(1))
    local oct = O.new(ub)
    local len = oct:__len()
    local bor = O.from_bin("0"):pad(len)
    local band = bor:__bnot()
    local start_index = 0
    for i = 0, N do 
        local u, c = FS.generate_nat(ub,transcript,start_index)
        assert(u:__lte(ub), "generate_nat() generated a number over the indicated limit")
        u = O.new(u)
        band = band:__band(u:reverse():pad(len):reverse())
        bor = bor:__bor(u:reverse():pad(len):reverse())
        start_index = c
    end 
    assert(band == O.from_bin("0"):pad(len), "NO RANDOM: a bit is always equal to 1" )
    assert(bor == mask(sub), "NO RANDOM: a bit is always equal to 0")
end 

num_1 = big.from_decimal("7")
num_2 = big.from_decimal("8")
num_3 = big.from_decimal("9")
num_4 = big.from_decimal("4294967295")
test_nat(transcript_1,num_1)
test_nat(transcript_1,num_2)
test_nat(transcript_1,num_3)
test_nat(transcript_1,num_4)
print("OK: test natural")


