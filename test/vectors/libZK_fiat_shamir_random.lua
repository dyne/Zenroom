local FS = require'libZK_fiat_shamir'

print("TEST VECTORS from Frigo's RFC")

local tr_1 = O.from_string("test")
local len_1 = O.from_number(tr_1:__len()):reverse():sub(1,8)
local zero = O.from_hex('00')
local transcript_1 = zero:__concat(len_1):__concat(tr_1)
local result_1 = FS.fiat_shamir(transcript_1,20,0):hex()
assert(result_1 == "ca44c5bc2d395c8b88a28891ccaa05b447ba00dc", "FS.fiat_shmair() doesn't return the expected stream")
local a, b = FS.fiat_shamir(transcript_1,5,0)
assert(a:__concat(FS.fiat_shamir(transcript_1,15,b)):eq(FS.fiat_shamir(transcript_1,20,0)), "FS.fiat_shmair():error in the generation of the script")
assert(FS.fiat_shamir(transcript_1,20,0):sub(6,15):eq(FS.fiat_shamir(transcript_1,10,b)), "FS.fiat_shmair():error in the generation of the script")
print("OK: generation of stream")

local m = big.from_decimal("1000000000")
local result_2 = FS.generate_nat(m,transcript_1,0)
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


local function test_nat(transcript, max_rand)
    --check that no bit is stuck at 0 or 1.
    assert(type(max_rand) == "zenroom.big", "m is not a BIG")
    local N = 100
    local sub = big.zensub(max_rand,big.new(1))
    local oct = O.new(max_rand)
    local len = oct:__len()
    local bor = O.from_bin("0"):pad(len)
    local band = bor:__bnot()
    local start_index = 0
    for i = 0, N do 
        generated_number, start_index = FS.generate_nat(max_rand,transcript,start_index)
        assert(generated_number:__lte(max_rand), "generate_nat() generated a number over the indicated limit")
        generated_number = O.new(generated_number)
        band = band:__band(generated_number:reverse():pad(len):reverse())
        bor = bor:__bor(generated_number:reverse():pad(len):reverse())
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


local p = big.from_decimal("18446744069414584321")
assert(FS.generate_field_element_p(transcript_1,p,0):hex() == "ca44c5bc2d395c8b", "FS.generate_field_element_p() doesn't return the expected random field element")
print("OK: test random field element")

local array = FS.generate_challenge_p(transcript_1,p,5,0)
assert(array[1]:hex() == "ca44c5bc2d395c8b" and 
    array[2]:hex() == "88a28891ccaa05b4" and 
    array[3]:hex() == "47ba00dc6a80e75f" and 
    array[4]:hex() == "878cb1c10006841e" and 
    array[5]:hex() == "4bfec61da916547c" ,
    "FS.generate_challenge_p() doesn't return the expected random numbers")


local function test_elt(transcript,p)
    local N = 30
    local Elt = FS.generate_challenge_p(transcript,p,N,0)
    for i = 1, N do 
        for j = 1, N do
            if i ~= j then 
                assert(Elt[i]~=Elt[j], "FS.generate_challenge_p() generates no random numbers")
            end 
        end 
    end 
end 

test_elt(transcript_1,p)
print("OK: test array of random field elements")

local function swap(array, i, j, n)
    local k = array[i]
    table.insert(array,i,array[j]) 
    table.remove(array,i+1)
    table.insert(array,j,k)
    table.remove(array,j+1)
    return array
end

local function choose(n, k, transcript)
    assert(k <= n, "k is bigger than n")
    local array = {}
    for i = 1, n do
        array[i] = i
    end 
    local start_index=0
    for i = 1, k do
        m, start_index = FS.generate_nat(big.new(n):__sub(big.new(i)), transcript, start_index)
        j = i + m:decimal()
        array = swap(array,i,j,n)
    end
    return array
end 

local function test_choose(transcript,n,k)
    local array = choose(n,k,transcript)
    for i = 1, k do 
        assert(array[i] <= n, "element in the array is bigger then n")
    end 
    table.sort(array)
    for i = 2, k do 
        assert(array[i-1] < array[i], "NO RANDOM: equal elements in the array")
    end 
end 

for k = 1, 33 do 
    test_choose(transcript_1, 33, k)
end 

test_choose(transcript_1,10000,42)
test_choose(transcript_1,10000,10000)

print("OK: test choose")

