-- recipe: merkle.root
-- input (DATA): JSON with { leaves: [hex...], hash: "sha256" }
-- output: JSON with { root: "hex..." }

local J = require'json'
local data = DATA and J.raw_decode(DATA) or {}

local MT = require'crypto_merkle'
local leaves = {}
for _, h in ipairs(data.leaves or {}) do
	table.insert(leaves, O.from_hex(h))
end

local root = MT.create_merkle_root(leaves, data.hash or 'sha256')
local out = J.raw_encode({root = root:hex()})
print(out)
