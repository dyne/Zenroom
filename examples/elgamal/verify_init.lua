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

proves = DATA_TABLE['proves']
scores = DATA_TABLE['scores']
size = math.max(#proves, #scores)

for i = 1, size do
  c = readBig(proves[i]['c'])
  rx = readBig(proves[i]['rx'])
  a = readEcp(scores[i]['a'])
  b = readEcp(scores[i]['b'])

  verifyzero(a, b, c, rx)
end
export = JSON.encode(
   {
      ok = true
   }
)
print(export)
