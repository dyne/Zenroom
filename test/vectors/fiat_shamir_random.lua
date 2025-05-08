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
result_2 = FS.generate_nat(m,transcript_1)
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





