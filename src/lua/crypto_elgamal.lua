-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- El-Gamal implementation by Alberto Sonnino and Denis Roio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local elg = { _VERSION = 'crypto_elgamal.lua 1.0' }

function elg.keygen()
   local d = INT.modrand(ECP.order())
   local gamma = d * ECP.generator()
   return d, gamma
end

function elg.encrypt(gamma, m, h)
   local k = INT.modrand(ECP.order())
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
