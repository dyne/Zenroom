--
-- Verifies that all scores are zero
--
-- Asserts if it's false
--

g = ECP.G() -- get the curve's generator coordinates
h = g * 2 -- hashtopoint "h0"
h1 = g * 20 -- hashtopoint "h1"
order = ECP.order() -- get the curves order in a big
rng = RNG.new()
H = HASH.new('sha256')

local DATA_TABLE = JSON.decode(DATA)

function readBig(str)
	return BIG.new(hex(str))
end 

function readEcp(table)
	local x = readBig(table['x'])
	local y = readBig(table['y'])

	return ECP.new(x, y)
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


function verifyzero(a, b, c, rx)
	local Aw = a * rx + b * c
	local Bw = g * rx + public * c

	local c_prime = to_challenge({g, h, public, a, b, Aw, Bw})
	assert(c_prime == c)
end


-- Load public data
public = readEcp(DATA_TABLE["public"])
proof = DATA_TABLE['proof']
scores = DATA_TABLE['scores']
outcome = DATA_TABLE['outcome']

scores = LAMBDA.map(scores, function(k,v) return { a = readEcp(v['a']), b = readEcp(v['b']) } end)
proof = LAMBDA.map(proof, function(k,v) return { c = readBig(v['c']), rx = readBig(v['rx']) } end)

size = math.max(#proof, #scores)

for i = 1, size do
	a = scores[i]['a']
	b = scores[i]['b']
	c = proof[i]['c']
	num_votes = BIG.new(outcome[i])
	rx = proof[i]['rx']

	b = b + (h * num_votes):negative()
	verifyzero(a, b, c, rx)
end

export = JSON.encode(
   {
      ok = true
   }
)
print(export)
