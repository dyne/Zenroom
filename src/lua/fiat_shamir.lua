local FS = {}

local function Aes(key, plaintext)
    local zero = O.from_hex('00000000000000000000000000000000')
    return AES.ctr_encrypt(key, zero, plaintext)
end

function FS.fiat_shamir(transcript,n_bytes,start_index)
    local key = sha256(transcript)
    local stream = O.new()
    local n_blocks = math.ceil(start_index/16)+math.ceil(n_bytes/16)
    for i = 0, n_blocks-1 do 
        stream = stream:__concat(Aes(key, O.from_number(i):reverse()))
    end 
    return stream:sub(start_index+1, start_index+n_bytes), start_index+n_bytes
end
    
local function ceil_div8(n)
    assert(type(n) == "zenroom.big", "m is not a BIG")
    if n:__mod(big.new(8)):__eq(big.new(0)) then
        return n:__div(big.new(8)) 
    else
        return n:__div(big.new(8)):__add(big.new(1))
    end 
end

function FS.generate_nat(m, transcript, start_index)
--generates a random natural between 0 and m-1 inclusive
    assert(type(m) == "zenroom.big", "m is not a BIG")
    assert(type(transcript) == "zenroom.octet", "transcript is not an octet")
    local l = big.new(0) 
    while big.new(2):modpower(l,ECP.order()):__lt(m) do
        l = big.zenadd(l,big.new(1))
    end
    local n_bytes = ceil_div8(l):int()
    local mod = big.new(2):modpower(l,ECP.order())
    local r = m
    while m:__lte(r) do 
        b, start_index = FS.fiat_shamir(transcript, n_bytes, start_index)
        local k = big.new(b:reverse())
        r = k:__mod(mod)
    end 
    return r, start_index
end 

function FS.generate_field_element_p(transcript,p,start_index)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local nat, si =  FS.generate_nat(p,transcript,start_index)
    oct = O.new(nat)
    return oct:reverse(), si
end 

function FS.generate_field_element_gf(transcript,deg,start_index)
    assert(type(deg) == "number", "deg is not a number")
    local n_bytes = deg/8
    local nat, si = FS.fiat_shamir(transcript,n_bytes,start_index)
    return nat, si
end

function FS.generate_challenge_p(transcript,p,len,start_index)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(len) == "number", "len is not a number")
    local array = {}
    for i = 1, len do 
        elt, start_index =  FS.generate_field_element_p(transcript,p,start_index)
        table.insert(array,elt)
    end
    return array, start_index
end 

function FS.generate_challenge_gf(transcript,deg,len,start_index)
    assert(type(deg) == "number", "deg is not a number")
    assert(type(len) == "number", "len is not a number")
    local array = {}
    for i = 1, len do 
        elt, start_index =  FS.generate_field_element_gf(transcript,deg,start_index)
        table.insert(array,elt)
    end
    return array, start_index
end 

return FS



