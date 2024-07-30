-- BBS common functions for the benchmark in Zenroom
--
-- Copyright (C) 2024 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public
-- License along with this program.  If not, see
-- <https://www.gnu.org/licenses/>.

BBS = require 'crypto_bbs'

function keygen(ctx)
    local res = { sk = BBS.keygen(ctx) }
    res.pk = BBS.sk2pk(res.sk)
    return res
end

function sign(ctx, keys, obj)
    return BBS.sign(ctx, keys.sk, keys.pk, nil, obj)
end

function verify(ctx, pk, sig, obj)
    return BBS.verify(ctx, pk, sig, nil, obj)
end

function create_proof(ctx, pk, sig, arr, disc)
    return BBS.proof_gen(ctx, pk, sig, nil, HEAD, arr, disc)
end

function verify_proof(ctx, pk, proof, arr, disc)
    return BBS.proof_verify(ctx, pk, proof, nil, HEAD, arr, disc)
end


-- generate messages and disclosure indexes

function generate_messages(num)
  local cls = { }
  for i=1,num do
    table.insert(cls, OCTET.random(32))
  end
  return cls
end

function random_indexes(arr, num)
    local max = #arr
    assert(num < max-1, "cannot generate disclosures, ratio too high: "..num.." of "..max)
    local pick
    local got = { }
    for i=1,num do
        pick = random16() % max
        while array_contains(got, pick) do
            pick = random16() % max
            if pick == 0 then pick = 1 end
        end
        table.insert(got, pick)
    end
    return got
end

function disclosed_messages(arr, indexes)
    local res = { }
    for k,v in pairs(indexes) do
        table.insert(res,arr[v])
    end
    return res
end
