--
-- Initialize all the votes to zero
--
-- Returns a list of votes encrypted, and the ZKP that all are zero
--

g = ECP.G() -- get the curve's generator coordinates
h = g * 2 -- hashtopoint "h0"
h1 = g * 20 -- hashtopoint "h1"
order = ECP.order() -- get the curves order in a big
rng = RNG.new()
H = HASH.new('sha256')

local KEYS_TABLE = JSON.decode(KEYS)
local DATA_TABLE = JSON.decode(DATA)

function readBig(str)
	return BIG.new(hex(str))
end 

function writeEcp(ecp)
	local x = ecp:x()
	local y = ecp:y()
	
	return { x = tostring(x), y = tostring(y) }
end

-- Concatenates everything and hashes it
function to_challenge(list)
	local c = ""
	for i = 1, #list do
		c = c .. tostring(list[i])
	end

	local hash = H:process(str(c))
	return BIG.new(hash)
end


-- Load private data
private = readBig(KEYS_TABLE["private"])
public = g * private



-- Creates a ZKP that (a,b) encrypts a value of 0
function provezero(a, b)
	local wx = rng:big()

	local Aw = a * wx
	local Bw = g * wx

	local c = to_challenge({g, h, public, a, b, Aw, Bw})

	local rx = (wx - c:modmul(private, order)) % order

	return c, rx
end

-- Creates a cipher with a message m
function encrypt(m)
	local k = rng:big() % order
	local a = g * k
	local b = (public * k) + h * BIG.new(m)

	return {
		k = k,
		a = a,
		b = b
	}
end


if DATA_TABLE then
    options = DATA_TABLE['options']
else
    options = {'yes', 'no'}
end

-- initial state of the options
scores = LAMBDA.map(options, function(k,v) return 0 end)

-- encrypt them
scores = LAMBDA.map(scores, function(k,v) return encrypt(v) end)
-- create the ZKP that they are zero
proves = LAMBDA.map(scores, function(k,v)
       				c, rx = provezero(v['a'], v['b'])
                                return { c = tostring(c), rx = tostring(rx) }
                                end)

-- convert the scores in a serializable form
scores = LAMBDA.map(scores, function(k,v) return { a = writeEcp(v['a']), b = writeEcp(v['b']) } end)


export = JSON.encode(
   {
      options = options,
      scores = scores,
      proves = proves,
      public = writeEcp(public)
   }
)
print(export)