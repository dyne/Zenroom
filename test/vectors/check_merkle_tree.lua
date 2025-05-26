
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

local pos = {1,2}
local proof = MT.generate_compressed_proof(pos, #leaves, tree)

assert(proof[1] == "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5")
assert(proof[2] == "f03808f5b8088c61286d505e8e93aa378991d9889ae2d874433ca06acabcd493")

local pos = {2,4}
local proof = MT.generate_compressed_proof(pos, #leaves, tree)

assert(proof[1] == "e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db")
assert(proof[2] == "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5")
assert(proof[3] == "4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a")

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


Print("TEST for MT.generate_proof from Frigo's code")

for number_leaves = 1, 64 do
    local leaves = {}
    for i = 1, number_leaves do
        local leaf = OCTET.from_number(i)
        table.insert(leaves, leaf)
    end

    local tree = MT.create_merkle_tree(leaves, 'sha256')
    local root = tree[1]
    local nproof = 7
    
    assert(number_leaves <= 2^(nproof-1))

    for pos = 1, number_leaves do
        local proof = MT.generate_proof(tree, pos)
        local size_proof = #proof
        
        assert(#proof <= nproof)
        assert(#proof >= 1)
        assert(0 == math.floor(number_leaves/2^(#proof)))

        if pos + 1 == number_leaves then
            assert(MT.merkle_tree_len(number_leaves) == #proof) 
        end

        proof[size_proof] = proof[size_proof]:shl_circular(1)
        assert(MT.verify_proof(proof, pos, root, number_leaves, 'sha256') ~= root)
        proof[size_proof] = proof[size_proof]:shr_circular(1)
        assert(MT.verify_proof(proof, pos, root, number_leaves, 'sha256') == root)
    end
end


print("TEST for MT.generate_compressed_proof from Frigo's code")

local size = {1, 10, 80}

for i = 1, 3 do
    for n = 200, 300 do
        local pos, leaves_for_proof, leaves, tree = MT.setup_batch(n, size[i], 'sha256')    -- size[i] is the test size
        local root = tree[1]
        local proof = MT.generate_compressed_proof(pos, n, tree)
        assert(MT.verify_compressed_proof(proof, leaves_for_proof, pos, n ,root, 'sha256'))
    end
end


local kTestSize = 80
for n = 200, 300 do
    local pos, leaves_for_proof, leaves, tree = MT.setup_batch(n, kTestSize , 'sha256')
    local root = tree[1]
    local proof = MT.generate_compressed_proof(pos, n, tree)
    local size_proof = #proof
    for ei = 1, size_proof do
        proof[size_proof] = proof[size_proof]:shl_circular(1)
        assert(MT.verify_compressed_proof(proof, leaves_for_proof, pos, n ,root, 'sha256') == false)
        proof[size_proof] = proof[size_proof]:shr_circular(1)
    end
end


print("TEST ZeroLengthProof from Frigo's code")
-- Testing MT.verify_compressed_proof in case of an empty proof is had
-- In the FIRST test the verify must be able to compute the root even though the empty proof since all leaves are had
-- In the SECOND test the verify mustn't be able to compute the root since only a leaf anche an empty proof are had 

local data = {
    "100",
    "101",
    "102",
    "103"
}

local tree = MT.create_merkle_tree(data, 'sha256')
local root = tree[1]

local empty_proof = {}

local leaves_for_proof4 = {}
for i = 1, 4 do
    table.insert(leaves_for_proof4, _hash(data2[i], 'sha256'))
end

local pos = {1,2,3,4}
assert(MT.verify_compressed_proof(empty_proof, leaves_for_proof4, pos, 4 ,root, 'sha256'))

local leaves_for_proof1 = {_hash(data2[1], 'sha256')}
local pos = {1}
assert(MT.verify_compressed_proof(empty_proof, leaves_for_proof1, pos, 1 ,root, 'sha256') == false)




