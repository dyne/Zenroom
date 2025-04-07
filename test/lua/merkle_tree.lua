print "Merkle tree test"

local function hash(data)
    return sha256(data)
end

-- Function to create a Merkle tree from a table of data
local function create_merkle_tree(data_table)
    local tree = {}

    -- Hash each piece of data and add to the tree
    for _, data in ipairs(data_table) do
        table.insert(tree, hash(data))
    end

    -- Build the tree by hashing pairs of nodes until a single hash (the root) is obtained
    while #tree > 1 do
        local temp_tree = {}
        for i = 1, #tree, 2 do
            if i + 1 <= #tree then
                local concatenated_hashes = tree[i] .. tree[i + 1]
                table.insert(temp_tree, hash(concatenated_hashes))
            else
                table.insert(temp_tree, tree[i])
            end
        end
        tree = temp_tree
    end

    return tree[1] -- The Merkle root
end

-- Function to verify the integrity of a Merkle tree
local function verify_merkle_tree(data_table, merkle_root)
    local computed_root = create_merkle_tree(data_table)
    return computed_root == merkle_root
end

local data = {
    "data1",
    "data2",
    "data3",
    "data4"
}

print'--test 1'
local merkle_root = create_merkle_tree(data)
assert(verify_merkle_tree(data, merkle_root))

data[2] = "tampered_data"
assert(not verify_merkle_tree(data, merkle_root))

print'test 1--OK'

local data = {
    "data1"
}

print'--test 2'
local merkle_root = create_merkle_tree(data)
assert(verify_merkle_tree(data, merkle_root))

data[1] = "tampered_data"
assert(not verify_merkle_tree(data, merkle_root))

print'test 2--OK'

local data = {
    tostring(OCTET.random(32)),
    tostring(OCTET.random(32)),
    tostring(OCTET.random(32))
}

print'--test 3'
local merkle_root = create_merkle_tree(data)
assert(verify_merkle_tree(data, merkle_root))

print 'test 3--OK'

print'--OK'