g = ECP.G() -- get the curve's generator coordinates
h = g * 2 -- hashtopoint "h0"
h1 = g * 20 -- hashtopoint "h1"
order = ECP.order() -- get the curves order in a big
rng = RNG.new()
H = HASH.new('sha256')

local DATA_TABLE = JSON.decode(DATA)
local KEYS_TABLE = JSON.decode(KEYS)

function readBig(str)
	return BIG.new(hex(str))
end 

function readEcp(table)
	local x = readBig(table['x'])
	local y = readBig(table['y'])

	return ECP.new(x, y)
end

function writeEcp(ecp)
	ecp = ecp:affine()
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


-- Creates a ZKP that (a,b) encrypts a value of 0
function provezero(a, b)
	local wx = rng:big()

	local Aw = a * wx
	local Bw = g * wx

	local c = to_challenge({g, h, public, a, b, Aw, Bw})

	local rx = (wx - c:modmul(private, order)) % order

	return c, rx
end

function generateLookupTable(max)
	table = {}

	for i = 0, max do
		local point = h * BIG.new(i)
		local s = tostring(point:x()) .. tostring(point:y())
		table[s] = i
	end

	return table
end

function lookup(point, lookupTable)

	if point:isinf() then -- TODO: check NOT 100% sure
		return 0
	end

	point = point:affine()
	local s = tostring(point:x()) .. tostring(point:y())
	return lookupTable[s]
end

function decrypt(a, b)
	x = (a * private):negative()
	y = b + x
	return y
end


lookupTable = generateLookupTable(100)


-- Load public data
public = readEcp(DATA_TABLE["public"])
private = readBig(KEYS_TABLE["private"])

scores = DATA_TABLE['scores']
scores = LAMBDA.map(scores, function(k,v) 
	a = readEcp(v['a'])
	b = readEcp(v['b'])

	return { a = a, b = b}
end)

-- decrypt the scores, now we have h*num_votes
outcome = LAMBDA.map(scores, function(k,v) return decrypt(v['a'], v['b']) end)

-- Lookup on the table for the exact num of votes
outcome = LAMBDA.map(outcome, function(k,v) return lookup(v, lookupTable) end)

proof = LAMBDA.map(outcome, function(i,v)
	a = scores[i]['a']
	b = scores[i]['b']
	num_votes = BIG.new(v)

	b = b + (h * num_votes):negative()

	c, rx = provezero(a, b)

	return { c = tostring(c) , rx = tostring(rx) }
end)

scores = LAMBDA.map(scores, function(k,v) return { a = writeEcp(v['a']), b = writeEcp(v['b'])} end)

export = JSON.encode(
   {
      outcome = outcome,
      proof = proof,
      scores = scores,
      public = writeEcp(public)
   }
)
print(export)

