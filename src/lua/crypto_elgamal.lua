-- El-Gamal cryptosystem implementation by Alberto Sonnino

-- Licensed under the terms of the GNU Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.  Unless required by applicable
-- law or agreed to in writing, software distributed under the License
-- is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied.

local elg = { _VERSION = 'crypto_elgamal.lua 1.0' }

local random = RNG.new()
local function rand() return INT.new(random, ECP.order()) end

function elg.keygen()
   local d = rand()
   local gamma = d * ECP.generator()
   return d, gamma
end

function elg.encrypt(gamma, m, h)
   local k = rand()
   local a = k * ECP.generator()
   -- TODO: argument checking and explicit ECP conversion
   -- if type(gamma) == "string" then
   -- 	  g = ECP.new(gamma) -- explicit conversion to ECP
   -- else g = gamma end -- other conversions are implicit
   local b = gamma * k
	  +
	  h * m
   return a, b, k
end

function elg.decrypt(d, a, b)
   return b - a * d
end

return elg
