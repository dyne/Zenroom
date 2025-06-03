local ENCODING = {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", 
    "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
}

local function encode_time()
    time = big.new(os.time())*big.new(1000)
    len = 10
    local result = {}
    for i = len, 1, -1 do 
        local mod = (time % big.new(32)):int() 
        result[i] = ENCODING[mod+1]
        time = (time - mod) / big.new(32)
    end 
    return table.concat(result)
end

local function encode_random()
    len = 16
    local result = {}
    for i = 1, len do
      result[i] = ENCODING[math.floor(math.random() * 32) + 1]
    end
    return table.concat(result)
end

local function ulid()
    return encode_time() .. encode_random()
end

print(ulid())
