--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

-- Elgamal based Additive Homomorphic commitment scheme 

local elgah = {
   _VERSION = 'crypto_elgamal.lua 0.5',
   _URL = 'https://zenroom.dyne.org',
   _DESCRIPTION = 'Elgamal based Additive Homomorphic commitment scheme ',
   _LICENSE = [[
Licensed under the terms of the GNU Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.  Unless required by applicable
law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.
]]
}

local G = ECP.generator() -- return value
local O  = ECP.order() -- return value


-- stateful challenge hardcoded string
local hs = ECP.hashtopoint(str([[
Jaromil started writing this code on Tuesday 21st January 2020
]] .. elgah._LICENSE))
local challenge = G:octet() .. hs:octet()
local function to_challenge(list)
   local ser = serialize(list)
   return INT.new( sha256( challenge .. ser.octets .. OCTET.from_string(ser.strings)))
end

function elgah.keygen()
	  local res = { private = INT.random() }
	  res.public = G * res.private
	  return(res)
end

function elgah.new(pub, m)
   -- sign == vote
   local k = INT.random()
   local hsm = hs * m -- optimisation
   -- vote encryption
   local enc_v = { left = G * k,
				   right = pub * k + hsm }
   -- opposite of vote encryption
   local enc_v_neg = { left = enc_v.left:negative(),
					   right = enc_v.right:negative() + hs }

   -- commitment to the vote
   local r = INT.random()
   local cv = G * r + hsm

   -- proof
   -- create the witnesess
   local wk = INT.random()
   local wm = INT.random()
   local wr = INT.random()

   local hswm = hs * wm -- optimisation
   -- compute the witnessess commitments
   local Aw = G  * wk
   local Bw = pub * wk + hswm
   local Cw = G  * wr + hswm

   -- create the challenge
   local c = to_challenge({enc_v.left, enc_v.right,
						   cv, Aw, Bw, Cw})
   -- create responses
   local rk = wk - c * k
   local rm = wm - c * m
   local rr = wr - c * r
   local pi = { c = c,
				rk = rk,
				rm = rm,
				rr = rr }

   -- signature's Theta
   return { value = { pos = enc_v,
					  neg = enc_v_neg }, -- left/right tuples
			cv = cv, -- ecp
			pi = pi } -- pi
end

function elgah.verify(pub, theta)
   -- recompute witnessess commitment
   ZEN.assert(theta.pi,   "ELGAH.verify 1st argument has no proof")
   ZEN.assert(theta.value,"ELGAH.verify 2nd argument has no value")

   local value = theta.value.pos
   local Aw = G * theta.pi.rk
	  + value.left * theta.pi.c
   local Bw = pub * theta.pi.rk
	  + hs * theta.pi.rm
	  + value.right * theta.pi.c
   local Cw = G * theta.pi.rr
	  + hs * theta.pi.rm
	  + theta.cv * theta.pi.c
   -- verify challenge
   ZEN.assert(theta.pi.c == to_challenge(
				 {value.left, value.right,
				  theta.cv, Aw, Bw, Cw }),
			  "ELGAH.verify: challenge fails")
   return true
end

function elgah.zero()
   return { pos = { left = ECP.infinity(), right = ECP.infinity() },
			neg = { left = ECP.infinity(), right = ECP.infinity() } }
end

function elgah.add(pub, a, b)
   elgah.verify(pub, a)
   local pos = { left = nil, right = nil }
   local neg = { left = nil, right = nil }
   pos.left  = a.value.pos.left  + b.pos.left
   pos.right = a.value.pos.right + b.pos.right
   neg.left  = a.value.neg.left  + b.neg.left
   neg.right = a.value.neg.right + b.neg.right
   return { pos = pos, neg = neg }
end

function elgah.sub(pub, a, b)
   elgah.verify(pub, a)
   local pos = { left = nil, right = nil }
   local neg = { left = nil, right = nil }
   pos.left  = a.value.pos.left  - b.pos.left
   pos.right = a.value.pos.right - b.pos.right
   neg.left  = a.value.neg.left  - b.neg.left
   neg.right = a.value.neg.right - b.neg.right
   return { pos = pos, neg = neg }
end

function elgah.tally(pub, priv, n)
   local wx = INT.random()
   local Aw = { wx:modneg(O) * n.pos.left,
				wx:modneg(O) * n.neg.left  }
   local c = to_challenge(Aw)
   local rx = wx - c * priv
   local dec = { pos = n.pos.left * priv:modneg(O),
				 neg = n.neg.left * priv:modneg(O) }
   -- return pi_tally
   return { dec = dec,
			rx  = rx,
			c   = c   }
end

function elgah.verify_tally(tally, value)
   local rxneg = tally.rx:modneg(O)
   local Aw = { rxneg * value.pos.left + tally.c * tally.dec.pos,
				rxneg * value.neg.left + tally.c * tally.dec.neg  }
   ZEN.assert(tally.c == to_challenge(Aw),
		  "ELGAH.verify_tally: challenge fails")
   return true
end

function elgah.count(tally, value, max)
   elgah.verify_tally(tally, value)
   local restab = { }
   max = max or 1000
   for idx=1,max do
	  restab[(BIG.new(idx) * hs):octet():url64()] = idx
   end
   local res = { pos = value.pos.right + tally.dec.pos,
				 neg = value.neg.right + tally.dec.neg  }
   return restab[res.pos:octet():url64()]
end

return elgah
