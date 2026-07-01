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

-- Lua wrapper for the secp256k1 point arithmetic module.
-- Mirrors src/lua/zenroom_ecp.lua but for secp256k1 instead of BLS381.
-- SECP.randomic is not provided: octet-based scalar generation should
-- be done at the caller level (use OCTET.random(32) and multiply G).

local secp = require("secp")

-- SECP.random: generate a random point by multiplying G with a random
-- scalar modulo the curve order.
function secp.random()
   local k = OCTET.random(32)
   return secp.generator() * k
end

return secp
