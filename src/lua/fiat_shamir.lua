local function Aes(key, plaintext)
    local zero = O.from_hex('00000000000000000000000000000000')
    return AES.ctr_encrypt(key, zero, plaintext)
end

local function fiat_shamir(transcript,n_bytes,start_index)
    local key = sha256(transcript)
    local stream = O.new()
    local n_blocks = math.ceil(start_index/16)+math.ceil(n_bytes/16)
    for i = 0, n_blocks-1 do 
        stream = stream:__concat(Aes(key, O.from_number(i):reverse()))
    end 
    return stream:sub(start_index+1, start_index+n_bytes), start_index+n_bytes
end
    

function generate_nat(m, transcript)
--generates a random natural between 0 and m-1 inclusive
    assert(type(m) == "zenroom.big", "m is not a BIG")
    assert(type(transcript) == "zenroom.octet", "transcript is not an octet")
    local l = big.new(0) 
    while big.new(2):modpower(l,ECP.order()):__lt(m) do
        l = big.zenadd(l,big.new(1))
    end
    local n_bytes = l:__div(big.new(8)):__add(big.new(1)):int()
    local mod = big.new(2):modpower(l,ECP.order())
    local r = m
    local start_index = 0 
    while m:__lte(r) do 
        local b = fiat_shamir(transcript, n_bytes, start_index)
        local k = big.new(b:reverse())
        r = k:__mod(mod)
        start_index = start_index+n_bytes
    end 
    return r
end 

transcript = O.from_string("tesefwfwddddfewf")
m = big.from_decimal("13675127219174")
result = generate_nat(m,transcript)
print(result:decimal())
print(m:decimal())
assert(result:__lte(m), "generate_nat() generated a number over the indicated limit")

