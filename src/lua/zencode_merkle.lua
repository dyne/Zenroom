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

When("create the merkle root of ''", 
    function(name)
        local data = ACK[name] 
        ACK.merkle_root = create_merkle_tree(data) 
    end
)
