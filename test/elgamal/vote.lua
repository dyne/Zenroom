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

local DATA_TABLE = JSON.decode(DATA)

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

-- Load public data
public = readEcp(DATA_TABLE["public"])


-- Creates a cipher with a message m
function encrypt(m)
	m = BIG.new(m)
	local k = rng:big() % order
	local a = g * k
	local b = (public * k) + h * m

	local c, rk, rm = provebinary(a, b, k, m)

	return {
		k = k,
		a = a,
		b = b,
		c = c,
		rk = rk,
		rm = rm
	}
end

function provebinary(a, b, k, m)
	-- prove that m is either 0 or 1
	local wk = rng:big()
	local wm = rng:big()

	local Aw = g * wk
	local Bw = public * wk + h * wm
	local Dw = g * wk + h1 * (m*(BIG.new(1)-m))

	local c = to_challenge({g, h, h1, a, b, Aw, Bw, Dw})

	local rk = (wk - c:modmul(k, order)) % order
	local rm = (wm - c:modmul(m, order)) % order

	return c, rk, rm
end

options = DATA_TABLE['options']
scores = DATA_TABLE['scores']

-- increment to do to the options
increment = {1, 0, 0}
-- encrypt them
increment = LAMBDA.map(increment, function(k,v) return encrypt(v) end)
provebin = LAMBDA.map(increment, function(k,v) return { c = tostring(v['c']), rk = tostring(v['rk']), rm = tostring(v['rm'])} end)


-- Load scores in json
prev_scores = LAMBDA.map(scores, function(k, v) 
								local a = readEcp(v['a'])
								local b = readEcp(v['b'])
								return { a = a, b = b}
							end)

new_scores = {}

for i = 1, #options do
	a = increment[i]['a'] + prev_scores[i]['a']
	b = increment[i]['b'] + prev_scores[i]['b']

	new_scores[i] = { a = a, b = b }
end

-- convert the scores in a serializable form
increment = LAMBDA.map(increment, function(k,v) return { a = writeEcp(v['a']), b = writeEcp(v['b']) } end)
new_scores = LAMBDA.map(new_scores, function(k,v) return { a = writeEcp(v['a']), b = writeEcp(v['b']) } end)

export = JSON.encode(
   {
      options = options,
      scores = new_scores,
      public = writeEcp(public),
      provebin = provebin,
      increment = increment,
   }
)
print(export)