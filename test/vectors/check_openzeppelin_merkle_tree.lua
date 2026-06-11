-- Vectors generated with @openzeppelin/merkle-tree v1.0.8.
-- Source: https://github.com/OpenZeppelin/merkle-tree

local MT = require'crypto_merkle'

local function octets(hex_values)
    local result = {}
    for i, value in ipairs(hex_values) do
        result[i] = O.from_hex(value)
    end
    return result
end

local function assert_octets(actual, expected, label)
    assert(#actual == #expected, label .. " length differs")
    for i, value in ipairs(expected) do
        assert(actual[i] == value, label .. " differs at index " .. i)
    end
end

local function assert_flags(actual, expected, label)
    assert(#actual == #expected, label .. " length differs")
    for i, value in ipairs(expected) do
        assert(actual[i] == value, label .. " differs at index " .. i)
    end
end

local function keccak256(data)
    return HASH.keccak256(data)
end

local simple_leaves = octets({
    "0000000000000000000000000000000000000000000000000000000000000001",
    "0000000000000000000000000000000000000000000000000000000000000002",
    "0000000000000000000000000000000000000000000000000000000000000003",
    "0000000000000000000000000000000000000000000000000000000000000004",
    "0000000000000000000000000000000000000000000000000000000000000005",
})

local simple_tree_expected = octets({
    "f6c00687a2a50c87101e36eddc215e458f8ca89ee0fb3be978e73e0ea380b768",
    "8ccb1afe9004b46e81f9742458856abcec79e407373a838bac2e3a4e97e00ec6",
    "2e174c10e159ea99b867ce3205125c24a42d128804e4070ed6fcc8cc98166aa0",
    "e90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0",
    "0000000000000000000000000000000000000000000000000000000000000005",
    "0000000000000000000000000000000000000000000000000000000000000004",
    "0000000000000000000000000000000000000000000000000000000000000003",
    "0000000000000000000000000000000000000000000000000000000000000002",
    "0000000000000000000000000000000000000000000000000000000000000001",
})

local simple_proofs_expected = {
    octets({
        "0000000000000000000000000000000000000000000000000000000000000002",
        "0000000000000000000000000000000000000000000000000000000000000005",
        "2e174c10e159ea99b867ce3205125c24a42d128804e4070ed6fcc8cc98166aa0",
    }),
    octets({
        "0000000000000000000000000000000000000000000000000000000000000001",
        "0000000000000000000000000000000000000000000000000000000000000005",
        "2e174c10e159ea99b867ce3205125c24a42d128804e4070ed6fcc8cc98166aa0",
    }),
    octets({
        "0000000000000000000000000000000000000000000000000000000000000004",
        "8ccb1afe9004b46e81f9742458856abcec79e407373a838bac2e3a4e97e00ec6",
    }),
    octets({
        "0000000000000000000000000000000000000000000000000000000000000003",
        "8ccb1afe9004b46e81f9742458856abcec79e407373a838bac2e3a4e97e00ec6",
    }),
    octets({
        "e90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0",
        "2e174c10e159ea99b867ce3205125c24a42d128804e4070ed6fcc8cc98166aa0",
    }),
}

local simple_tree, simple_indices =
    MT.create_openzeppelin_merkle_tree(simple_leaves)
assert_octets(simple_tree, simple_tree_expected, "SimpleMerkleTree")

for i, expected in ipairs(simple_proofs_expected) do
    local proof = MT.generate_openzeppelin_proof(simple_tree, simple_indices[i])
    assert_octets(proof, expected, "SimpleMerkleTree proof " .. i)
    assert(MT.process_openzeppelin_proof(simple_leaves[i], proof)
        == simple_tree[1], "SimpleMerkleTree proof root differs")
end

local simple_multiproof =
    MT.generate_openzeppelin_multiproof(simple_tree, {
        simple_indices[1],
        simple_indices[3],
        simple_indices[5],
    })
assert_octets(simple_multiproof.leaves,
    {simple_leaves[1], simple_leaves[3], simple_leaves[5]},
    "SimpleMerkleTree multiproof leaves")
assert_octets(simple_multiproof.proof,
    {simple_leaves[2], simple_leaves[4]},
    "SimpleMerkleTree multiproof proof")
assert_flags(simple_multiproof.proof_flags,
    {false, false, true, true},
    "SimpleMerkleTree multiproof flags")
assert(MT.process_openzeppelin_multiproof(simple_multiproof)
    == simple_tree[1], "SimpleMerkleTree multiproof root differs")

local empty_multiproof =
    MT.generate_openzeppelin_multiproof(simple_tree, {})
assert_octets(empty_multiproof.leaves, {},
    "SimpleMerkleTree empty multiproof leaves")
assert_octets(empty_multiproof.proof, {simple_tree[1]},
    "SimpleMerkleTree empty multiproof proof")
assert_flags(empty_multiproof.proof_flags, {},
    "SimpleMerkleTree empty multiproof flags")
assert(MT.process_openzeppelin_multiproof(empty_multiproof)
    == simple_tree[1], "SimpleMerkleTree empty multiproof root differs")

local unsorted_leaves = {
    simple_leaves[5],
    simple_leaves[1],
    simple_leaves[4],
    simple_leaves[2],
    simple_leaves[3],
}
local unsorted_tree_expected = octets({
    "79cff200fc902bb45baa843d620c3c866c72e36f4a5e0e38f38aea3d2bd4fdb6",
    "ae0d4d0ca061c554e850c8013a76c42d75d5ba7cebc01d1240c06efd18fbf8e5",
    "91da3fd0782e51c6b3986e9e672fd566868e71f3dbc2d6c2cd6fbb3e361af2a7",
    "1471eb6eb2c5e789fc3de43f8ce62938c7d1836ec861730447e2ada8fd81017b",
    "0000000000000000000000000000000000000000000000000000000000000003",
    "0000000000000000000000000000000000000000000000000000000000000002",
    "0000000000000000000000000000000000000000000000000000000000000004",
    "0000000000000000000000000000000000000000000000000000000000000001",
    "0000000000000000000000000000000000000000000000000000000000000005",
})
local unsorted_tree, unsorted_indices =
    MT.create_openzeppelin_merkle_tree(unsorted_leaves, false)
assert_octets(unsorted_tree, unsorted_tree_expected,
    "SimpleMerkleTree without leaf sorting")
assert_flags(unsorted_indices, {9, 8, 7, 6, 5},
    "SimpleMerkleTree unsorted indices")

local standard_values = {
    {"1111111111111111111111111111111111111111", 1},
    {"2222222222222222222222222222222222222222", 200},
    {"3333333333333333333333333333333333333333", 30000},
    {"4444444444444444444444444444444444444444", 4000000},
    {"5555555555555555555555555555555555555555", 500000000},
}

local standard_leaves = {}
for i, value in ipairs(standard_values) do
    local abi_encoded = O.from_hex(value[1]):pad(32)
        .. BIG.new(value[2]):octet():pad(32)
    standard_leaves[i] = keccak256(keccak256(abi_encoded))
end

local standard_leaves_expected = octets({
    "60648906e1a3f55dd188e992dc24db68c6b6d455fe925705f5e110ed7889ad90",
    "fc0b9d0cc7c164a3e1e85418b826258293d9857a99b368c8913c3d6bac361b66",
    "5ee9cb0672c93f38405dafaf253b712e1b492c2725f92717255a901ce537d9a1",
    "cd27d1bb4f76030e7ebb1843d611f35a4e5675b6e4bab42abab0485619ca1310",
    "1f8c3264407e5e9b7eddcf9b3e49e0530f7ce6e50805bf634cb21f06bfe5c807",
})
assert_octets(standard_leaves, standard_leaves_expected,
    "StandardMerkleTree leaf hashes")

local standard_tree_expected = octets({
    "16e56eb297256a3d330955fcd855753c7cbc2adccf23e1c8918c537fdf27e7f9",
    "0160d70b7f7211f934ef8fa742c8865b696e6a97bf709dfc16f5244b84a707bc",
    "7a5f3c61d065c714c73a41b75e0224510a325e8436a003d9fb625aa9e105ed49",
    "78a1343d5bfa2e67f7723b5099747f2bb697c115ab4a9b94e7512878520fd251",
    "fc0b9d0cc7c164a3e1e85418b826258293d9857a99b368c8913c3d6bac361b66",
    "cd27d1bb4f76030e7ebb1843d611f35a4e5675b6e4bab42abab0485619ca1310",
    "60648906e1a3f55dd188e992dc24db68c6b6d455fe925705f5e110ed7889ad90",
    "5ee9cb0672c93f38405dafaf253b712e1b492c2725f92717255a901ce537d9a1",
    "1f8c3264407e5e9b7eddcf9b3e49e0530f7ce6e50805bf634cb21f06bfe5c807",
})

local standard_tree, standard_indices =
    MT.create_openzeppelin_merkle_tree(standard_leaves)
assert_octets(standard_tree, standard_tree_expected, "StandardMerkleTree")

local standard_proofs_expected = {
    octets({
        "cd27d1bb4f76030e7ebb1843d611f35a4e5675b6e4bab42abab0485619ca1310",
        "0160d70b7f7211f934ef8fa742c8865b696e6a97bf709dfc16f5244b84a707bc",
    }),
    octets({
        "78a1343d5bfa2e67f7723b5099747f2bb697c115ab4a9b94e7512878520fd251",
        "7a5f3c61d065c714c73a41b75e0224510a325e8436a003d9fb625aa9e105ed49",
    }),
    octets({
        "1f8c3264407e5e9b7eddcf9b3e49e0530f7ce6e50805bf634cb21f06bfe5c807",
        "fc0b9d0cc7c164a3e1e85418b826258293d9857a99b368c8913c3d6bac361b66",
        "7a5f3c61d065c714c73a41b75e0224510a325e8436a003d9fb625aa9e105ed49",
    }),
    octets({
        "60648906e1a3f55dd188e992dc24db68c6b6d455fe925705f5e110ed7889ad90",
        "0160d70b7f7211f934ef8fa742c8865b696e6a97bf709dfc16f5244b84a707bc",
    }),
    octets({
        "5ee9cb0672c93f38405dafaf253b712e1b492c2725f92717255a901ce537d9a1",
        "fc0b9d0cc7c164a3e1e85418b826258293d9857a99b368c8913c3d6bac361b66",
        "7a5f3c61d065c714c73a41b75e0224510a325e8436a003d9fb625aa9e105ed49",
    }),
}

for i, expected in ipairs(standard_proofs_expected) do
    local proof = MT.generate_openzeppelin_proof(
        standard_tree, standard_indices[i])
    assert_octets(proof, expected, "StandardMerkleTree proof " .. i)
    assert(MT.process_openzeppelin_proof(standard_leaves[i], proof)
        == standard_tree[1], "StandardMerkleTree proof root differs")
end

local standard_multiproof =
    MT.generate_openzeppelin_multiproof(standard_tree, {
        standard_indices[1],
        standard_indices[3],
        standard_indices[5],
    })
assert_octets(standard_multiproof.leaves,
    {standard_leaves[5], standard_leaves[3], standard_leaves[1]},
    "StandardMerkleTree multiproof leaves")
assert_octets(standard_multiproof.proof,
    {standard_leaves[4], standard_leaves[2]},
    "StandardMerkleTree multiproof proof")
assert_flags(standard_multiproof.proof_flags,
    {true, false, false, true},
    "StandardMerkleTree multiproof flags")
assert(MT.process_openzeppelin_multiproof(standard_multiproof)
    == standard_tree[1], "StandardMerkleTree multiproof root differs")

print("OpenZeppelin Merkle tree v1.0.8 parity: OK")
