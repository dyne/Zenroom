--[[
--This file is part of zenroom
--
--Copyright (C) 2023 Dyne.org foundation
--designed, written and maintained by Rebecca Selvaggini, Luca Di Domenico
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
--]]

-- TODO: Tonelli-Shanks (in zen_ecdh.c maybe)

local PVSS = {}

-- TODO: use secp256k1 (apparently ECDH, but ECDH.generator() does NOT exists,
-- and in the ECDH files only ECP_ZZZ_generator is called)
local CURVE_ORDER = ECP.order()

-- This function implements the creation of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
function PVSS.create_proof_DLEQ(points_tables, alpha_array, options)
    -- points_tables is an array where each component is {g1, h1, g2, h2, alpha}.
    -- alpha is such that g1^alpha = h1 and g2^alpha = h2

    local hash_function = options.hash or sha256
    local w_array = {}
    local r_array = {}
    local concat = O.empty()
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local w = BIG.modrand(CURVE_ORDER)
        w_array[k] = w
        local a1 = g1 * w
        local a2 = g2 * w
        concat = concat .. h1:zcash_export() .. h2:zcash_export() .. a1:zcash_export() .. a2:zcash_export()
    end

    local c = hash_function(concat)
    c = BIG.mod( BIG.new(c) , CURVE_ORDER)

    for k,alpha in pairs(alpha_array) do
        local r = alpha:modmul(c, CURVE_ORDER)
        r_array[k] = BIG.modsub(w_array[k], r, CURVE_ORDER)
    end

    return c, r_array
end

-- This function implements the verification of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
function PVSS.verify_proof_DLEQ(points_tables, c, r_array, options)

    local hash_function = options.hash or sha256
    local concat = O.empty()
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local r = r_array[k]
        local a1 = (g1 * r) + (h1 * c)
        local a2 = (g2 * r) + (h2 * c)
        concat = concat .. h1:zcash_export() .. h2:zcash_export() .. a1:zcash_export() .. a2:zcash_export()
    end

    local digest = hash_function(concat)

    if ( (BIG.mod( BIG.new(digest) , CURVE_ORDER)) == c) then
        return true
    end
    return false

end

return PVSS
