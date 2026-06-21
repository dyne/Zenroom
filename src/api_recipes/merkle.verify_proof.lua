-- recipe: merkle.verify_proof
-- input (DATA): JSON with { proof: [hex...], position: int, root: "hex", leaf_count: int, hash: "sha256" }
-- output: JSON with { valid: bool }

local J = require'json'
local data = DATA and J.raw_decode(DATA) or {}

local MT = require'crypto_merkle'
local proof = {}
for _, p in ipairs(data.proof or {}) do
	table.insert(proof, O.from_hex(p))
end

local ok = MT.verify_proof(
	proof,
	data.position or 0,
	O.from_hex(data.root or ''),
	data.leaf_count or 0,
	data.hash or 'sha256'
)
local out = J.raw_encode({valid = ok})
print(out)
