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

local function _export_big_as_octet_f(obj)
    if type(obj) == 'zenroom.big' then
        return obj:octet():base64()
    end
    return obj
end
function single_share_f(o)
   local obj = deepmap(CONF.input.encoding.fun, o)
   return { x = ZEN.get(obj, 'x', BIG.new, O.from_base64),
            y = ZEN.get(obj, 'y', BIG.new, O.from_base64) }
end
ZEN.add_schema({
      -- single share
      single_share = {
        import = single_share_f,
        export = _export_big_as_octet_f,
      },
      -- array of single shares
      secret_shares = {
          import = function(obj)
              local res = { }
              for k,v in pairs(obj) do
                  res[k] = single_share_f(v)
              end
              return res
          end,
          export = function(obj)
              local res = { }
              for k,v in pairs(obj) do
                  res[k] = {
                      x = _export_big_as_octet_f(v.x),
                      y = _export_big_as_octet_f(v.y),
                  }
              end
              return res
          end,
      }
})

When("create the secret shares of '' with '' quorum ''", function(sec, tot, q)
	local soct = have(sec)
	-- this check is relative to the BIG size, established by curve's size
	-- it is made inside the crypto function, but could also be made here
	-- local sbig = BIG.new(soct) % ECP.order()
	-- ZEN.assert(sbig:octet() == soct, "Secret too big to share: "..#soct.." bytes")
	local total = tonumber(tot)
	ZEN.assert(total, "Total shares is not a number: "..tot)
	local quorum = tonumber(q)
	ZEN.assert(quorum, "Quorum shares is not a number: "..q)
        ACK.secret_shares = LAG.create_shared_secret(total,quorum,soct)
        new_codec('secret_shares', {
            encoding="complex",
            zentype="schema",
            schema="secret_shares",
        })
end)

When("compose the secret using ''", function(shares)
	local sh = have(shares)
        ACK.secret = LAG.compose_shared_secret(sh):octet()
        new_codec('secret', {
            encoding="base64",
            zentype="element",
        })
end)
