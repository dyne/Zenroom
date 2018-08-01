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

-- decrypt the scores, now we have h*num_votes
scores = LAMBDA.map(scores, function(k,v) 
	a = readEcp(v['a'])
	b = readEcp(v['b'])
	
	d = decrypt(a, b)
	return d
 end)

-- Lookup on the table for the exact num of votes
scores = LAMBDA.map(scores, function(k,v) return lookup(v, lookupTable) end)

export = JSON.encode(
   {
      scores = scores
   }
)
print(export)

