-- Initialisation
rng = RNG.new() -- initialise a new random number generator
g = ECP.G() -- get the curve's generator coordinates
h = g * 2 -- hashtopoint "h0"
h1 = g * 20 -- hashtopoint "h1"

order = ECP.order() -- get the curves order in a big
H = HASH.new('sha256')

function to_challenge(list)
	local c = ""
	for i = 1, #list do
		c = c .. tostring(list[i])
	end

	local hash = H:process(str(c))
	return BIG.new(hash)
end

function provezero(g, h0, order, pub, a, b, priv)
	local wx = rng:big()

	local Aw = a * wx
	local Bw = g * wx

	local c = to_challenge({g, h0, pub, a, b, Aw, Bw})

	local rx = (wx - c:modmul(priv, order)) % order

	return c, rx
end

function verifyzero(g, h0, order, pub, a, b, c, rx)
	local Aw = a * rx + b * c
	local Bw = g * rx + pub * c

	local c_prime = to_challenge({g, h0, pub, a, b, Aw, Bw})
	assert(c_prime == c)
end

function provebinary(g, h0, h1, order, pub, a, b, k, m)
	-- prove that m is either 0 or 1
	local wk = rng:big()
	local wm = rng:big()

	local Aw = g * wk
	local Bw = pub * wk + h0 * wm
	local Dw = g * wk + h1 * (m*(BIG.new(1)-m))

	local c = to_challenge({g, h0, h1, a, b, Aw, Bw, Dw})

	local rk = (wk - c:modmul(k, order)) % order
	local rm = (wm - c:modmul(m, order)) % order

	return c, rk, rm
end

function verifybinary(g, h0, h1, order, pub, a, b, c, rk, rm)
	local Aw = a * c + g * rk
	local Bw = b * c + pub * rk + h0 * rm
	local Dw = a * c + g * rk  + h1 * BIG.new(0)

	-- compute the challenge prime
	c_prime = to_challenge({g, h0, h1, a, b, Aw, Bw, Dw})
	assert(c_prime == c)
end

-- ElGamal Key Generation
private = rng:big() % order
public = g * private


-- Start the bin with state of 0
k = rng:big() % order
a = g * k
b = (public * k) + h * BIG.new(0)
local c, rx = provezero(g, h, order, public, a, b, private)

-- CHECKERS verification
verifyzero(g, h, order, public, a, b, c, rx)


-- Increment the value in 1
m2 = BIG.new(1)
k2 = rng:big() % order
a2 = g * k2
b2 = (public * k2) + h * m2
local c, rk, rm = provebinary(g, h, h1, order, public, a2, b2, k2, m2)

-- CHECKER verify (this prevent to increment by none binary values (0 and 1))
verifybinary(g, h, h1, order, public, a2, b2, c, rk, rm)

-- Sum both messages
k = k + k2
a = a + a2
b = b + b2

-- Increment by one again
m2 = BIG.new(1)
k2 = rng:big() % order
a2 = g * k2
b2 = (public * k2) + h * m2
local c, rk, rm = provebinary(g, h, h1, order, public, a2, b2, k2, m2)

-- CHECKER verify (this prevent to increment by none binary values (0 and 1))
verifybinary(g, h, h1, order, public, a2, b2, c, rk, rm)

-- Sum both messages
k = k + k2
a = a + a2
b = b + b2

-- Decrypt
x = (a * private):negative()
y = b + x
assert(y == h * BIG.new(2)) -- 2 since we did increment the 0 state twice
