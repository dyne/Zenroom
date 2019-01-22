--
-- Verifies that all scores are zero
--
-- Asserts if it's false
--

g = ECP.G() -- get the curve's generator coordinates
h = g * INT.new(2) -- hashtopoint "h0"
h1 = g * INT.new(20) -- hashtopoint "h1"
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

function verifyone(a, b, c, rk)
	local Aw = g * rk + a * c
	local Bw = public * rk + b * c + h * (BIG.new(1) + c:modneg(order))

	c_prime = to_challenge({g, h, public, a, b, Aw, Bw})
	assert(c_prime == c)
end


-- Load public data
public = readEcp(DATA_TABLE["public"])


-- verify that increments where either 0 or 1
proves = DATA_TABLE['provebin']
increment = DATA_TABLE['increment']
increment = LAMBDA.map(increment, function(k,v) return { a = readEcp(v['a']), b = readEcp(v['b']) } end)
size = math.max(#proves, #increment)

for i = 1, size do

  c = readBig(proves[i]['c'])
  rm = readBig(proves[i]['rm'])
  rk = readBig(proves[i]['rk'])

  a = increment[i]['a']
  b = increment[i]['b']
  verifybinary(a, b, c, rk, rm)
end

-- verify that sum of increments is 1
sum_a = increment[1]['a']
sum_b = increment[1]['b']
for i =2, #increment do
	sum_a = sum_a + increment[i]['a']
	sum_b = sum_b + increment[i]['b']
end
c = readBig(DATA_TABLE['prove_sum_one']['c'])
rk = readBig(DATA_TABLE['prove_sum_one']['rk'])
verifyone(sum_a, sum_b, c, rk)

export = JSON.encode(
   {
      ok = true
   }
)
print(export)
