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
    


