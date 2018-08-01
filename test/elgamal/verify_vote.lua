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


function verifybinary(a, b, c, rk, rm)
	local Aw = a * c + g * rk
	local Bw = b * c + public * rk + h * rm
	local Dw = a * c + g * rk  + h1 * BIG.new(0)

	-- compute the challenge prime
	c_prime = to_challenge({g, h, h1, a, b, Aw, Bw, Dw})
	assert(c_prime == c)
end


-- Load public data
public = readEcp(DATA_TABLE["public"])

proves = DATA_TABLE['provebin']
increment = DATA_TABLE['increment']

size = math.max(#proves, #increment)

for i = 1, size do

  c = readBig(proves[i]['c'])
  rm = readBig(proves[i]['rm'])
  rk = readBig(proves[i]['rk'])

  a = readEcp(increment[i]['a'])
  b = readEcp(increment[i]['b'])
  verifybinary(a, b, c, rk, rm)
end