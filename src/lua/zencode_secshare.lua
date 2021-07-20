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

-- Lagrange interpolation implementation in Zencode

LAG = require_once('crypto_lagrange_interpolation')

function single_share_f(o)
   local obj = deepmap(CONF.input.encoding.fun, o)
   return { x = ZEN.get(obj, 'x', BIG.new),
            y = ZEN.get(obj, 'y', BIG.new) }
end

ZEN.add_schema({
      -- sigle share
      single_share = signel_share_f,
      -- array of single shares
      secret_shares = function(obj)
         local res = { }
         for k,v in pairs(obj) do
            res[k] = single_share_f(v)
         end
         return res
      end
})

When("create the secret shares of '' with '' quorum ''", function(sec, tot, q)
		local s = ACK[sec]
		ZEN.assert(s, "Secret not found: "..sec)
		ZEN.assert(#s <= 32, "Secret too big to share: "..#s.." bytes, max is 32 bytes")
		local total = tonumber(tot)
		ZEN.assert(total, "Total shares is not a number: "..tot)
		local quorum = tonumber(q)
		ZEN.assert(quorum, "Quorum shares is not a number: "..q)
        ACK.secret_shares = LAG.create_shared_secret(total,quorum,s)
end)

When("compose the secret using ''", function(shares)
		ZEN.assert(ACK[shares], "Shares not found: "..shares)
        ACK.secret = LAG.compose_shared_secret(ACK[shares])
end)
