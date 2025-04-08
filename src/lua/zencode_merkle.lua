local function hash(data, hashtype)
    hashtype = hashtype or CONF.hash
    --default hashtype: sha256
    --possible hashtype:
    --sha512 
    --sha3_256 
    --sha3_512 
    --shake256 
    --keccak256
    local _hf <const> = HASH:init(hashtype)
    return _hf:process(data)
end

-- Function to create a Merkle tree from a table of data
local function create_merkle_tree(data_table, hastype)
    local tree = {}

    -- Hash each piece of data and add to the tree
    for _, data in ipairs(data_table) do
        table.insert(tree, hash(data, hashtype))
    end

    -- Build the tree by hashing pairs of nodes until a single hash (the root) is obtained
    while #tree > 1 do
        local temp_tree = {}
        for i = 1, #tree, 2 do
            if i + 1 <= #tree then
                local concatenated_hashes = tree[i] .. tree[i + 1]
                table.insert(temp_tree, hash(concatenated_hashes, hastype))
            else
                table.insert(temp_tree, tree[i])
            end
        end
        tree = temp_tree
    end

    return tree[1] -- The Merkle root
end

When("create merkle root of ''", 
    function(name)
        local data = ACK[name] 
        if type(data) ~= 'table' then
            error("Can only use tables")
        end
        ACK.merkle_root = create_merkle_tree(data) 
        new_codec('merkle root', {zentype = "string"})
    end
)

When("create merkle root of '' using hash ''", 
    function(name, hash)
        local data = ACK[name] 
        if type(data) ~= 'table' then
            error("Can only use tables")
        end
        ACK.merkle_root = create_merkle_tree(data, hash) 
        new_codec('merkle root', {zentype = "string"})
    end
)

When("create merkle root of dictionary path ''",
    function(name)
        local data, _ = pick_from_path(name)
        if type(data) ~= 'table' then
            error("Can only use tables")
        end
        ACK.merkle_root = create_merkle_tree(data) 
        new_codec('merkle root', {zentype = "string"})
    end
)

When("create merkle root of dictionary path '' using hash ''",
    function(name, hash)
        local data, _ = pick_from_path(name)
        if type(data) ~= 'table' then
            error("Can only use tables")
        end
        ACK.merkle_root = create_merkle_tree(data, hash) 
        new_codec('merkle root', {zentype = "string"})
    end
)