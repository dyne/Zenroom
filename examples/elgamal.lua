require('ecp')
require('big')

function randomOctet ()
  local random = octet.from_base64("ChW5qi5y//ISDIHKx5Fvxl+XY8IyDGVBHUfELp3PqJQ=");
  random:random()
  return random
end

function randomBig ()
  local random = randomOctet()
  return big.new(random)
end


local g = ecp:generator()
local h = g * 2; -- g.hastToPoint("h0")
local order = ecp:order()

-- ElGamal Key Generation
local seckey = randomBig()
local pubkey = g * seckey

-- Encrypt a msg with 1
local k = randomBig() -- big:random(order)
local a = g * k
local b = (pubkey * k) + h * big.new(1)

-- Encrypt a msg with 2
local k2 = randomBig() -- big.random(order)
local a2 = g * k
local b2 = (pubkey * k) + h * big.new(2)

-- Sum both messages
local sum_k = k + k2
local sum_a = a + a2
local sum_b = b + b2

-- Decrypt
local x = (sum_a * seckey):negative()
local y = sum_b + x

assert(y == h * big.new(3))
