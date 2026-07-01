--[[
-- This file is part of zenroom
--
-- Copyright (C) 2024-2026 Dyne.org foundation
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
--]]

-- Pedersen commitments over secp256k1: C = m*G + r*H
--
-- Uses a domain-separated nothing-up-my-sleeve second generator H,
-- derived via SECP.mapit with a fixed 64-byte seed.
-- This is NOT an extractable commitment scheme by itself; it provides
-- statistical hiding and computational binding assuming discrete log
-- is hard on secp256k1.
--
-- @module crypto_pedersen

local pedersen = {}
local S = SECP
local G = S.generator()

-- Derive H deterministically via hash-to-point.
-- The seed is a fixed domain-separated string, hashed with SHA-512.
-- H = mapit(sha512("Zenroom/Pedersen/secp256k1/H"))
local H_SEED = "Zenroom/Pedersen/secp256k1/H"
local _H = nil

local function get_H()
   if not _H then
      local seed_hash = sha512(H_SEED)
      _H = S.mapit(seed_hash)
   end
   return _H
end

-- Commit to a message m with blinding factor r.
-- C = m*G + r*H
--
-- @function pedersen.commit
-- @param m 32-byte OCTET scalar (the value to commit to)
-- @param r 32-byte OCTET scalar (random blinding factor)
-- @return SECP point C = m*G + r*H
function pedersen.commit(m, r)
   if iszen(type(m)) then m = m:octet() end
   if iszen(type(r)) then r = r:octet() end
   if #m ~= 32 then error("message scalar must be 32 bytes", 2) end
   if #r ~= 32 then error("blinding factor must be 32 bytes", 2) end
   local H = get_H()
   local mG = G * m
   local rH = H * r
   return mG + rH
end

-- Open a commitment: verify that C = m*G + r*H.
--
-- @function pedersen.open
-- @param C SECP point (the commitment)
-- @param m 32-byte OCTET scalar
-- @param r 32-byte OCTET scalar
-- @return true if C = m*G + r*H
function pedersen.open(C, m, r)
   if iszen(type(m)) then m = m:octet() end
   if iszen(type(r)) then r = r:octet() end
   local expected = pedersen.commit(m, r)
   return C == expected
end

-- Return the second generator H (for protocols that need it explicitly).
--
-- @function pedersen.H
-- @return SECP point H (the second generator)
function pedersen.H()
   return get_H()
end

-- Homomorphic addition of two commitments.
-- C = C1 + C2 (equivalent to commit(m1+m2, r1+r2))
--
-- @function pedersen.add
-- @param C1 SECP point
-- @param C2 SECP point
-- @return SECP point C1 + C2
function pedersen.add(C1, C2)
   return C1 + C2
end

return pedersen
