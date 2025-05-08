
local MT = require'crypto_merkle'

local function _hash(data, hashtype)
    hashtype = hashtype or CONF.hash
    local _hf <const> = HASH:init(hashtype)
    return _hf:process(data)
end

print("TEST VECTORS from Frigo's RFC")

local leaves1 = O.from_hex("4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a")
local leaves2 = O.from_hex("dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986")
local leaves3 = O.from_hex("084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5")
local leaves4 = O.from_hex("e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71")
local leaves5 = O.from_hex("e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db")

local root = O.from_hex("f22f4501ffd3bdffcecc9e4cd6828a4479aeedd6aa484eb7c1f808ccf71c6e76")

local leaves = {leaves1, leaves2, leaves3, leaves4, leaves5}

-- Used a special version for the creation of the merkle tree that supposes test vectors already hashed
local tree = MT.create_merkle_tree_from_table_of_hashes(leaves, "sha256")
assert(tree[1] == root, "The root of the tree does not match the expected value")

print("TEST from Frigo's code")

local leaves1 = "100"
local leaves2 = "101"
local leaves3 = "102"
local leaves4 = "103"

local leaves = {leaves1, leaves2, leaves3, leaves4}

local tree = MT.create_merkle_tree(leaves, "sha256")
local root = MT.create_merkle_root(leaves,"sha256")

for i = 1, 4 do
    assert(tree[4 + i -1] == _hash(leaves[i], "sha256"), "Leaf "..i.." does not match the expected value")
end

assert(tree[3] == _hash(_hash(leaves[3],"sha256") .. _hash(leaves[4], "sha256"), "sha256"), "Leaf 4 does not match the expected value")
assert(tree[2] == _hash(_hash(leaves[1],"sha256") .. _hash(leaves[2], "sha256"), "sha256"), "Leaf 3 does not match the expected value")

local leaves5 = _hash(_hash(leaves[1],"sha256") .. _hash(leaves[2], "sha256"), "sha256")
local leaves6 = _hash(_hash(leaves[3],"sha256") .. _hash(leaves[4], "sha256"), "sha256")

--tree[2] is the root
--used both since zencode_merkle.lua has a function that generates directly the root

assert(tree[1] == _hash(leaves5 .. leaves6, "sha256"), "Leaf 2 does not match the expected value")
assert(root == _hash(leaves5 .. leaves6, "sha256"), "Root does not match the expected value")






