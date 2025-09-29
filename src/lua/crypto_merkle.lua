--[[
--This file is part of zenroom
--
--Copyright (C) 2025 Dyne.org foundation
--designed, written and maintained by Nicola Suzzi and Matteo Cristino
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
-- Sources of the code are the following:
-- https://datatracker.ietf.org/doc/draft-google-cfrg-libzk/  Matteo Frigo RFC, last updated version 2025-03-03, draft (first version)
-- https://github.com/google/longfellow-zk/tree/main/lib/merkle 
--
--Last modified by Matteo Cristino
--on Thursday, 27th May 2025
--]]

local MT = {}

-- possible hashtype:
-- sha256 (default)
-- sha512
-- sha3_256
-- sha3_512
-- shake256
-- keccak256
local function _hash(data, hashtype)
    hashtype = hashtype or CONF.hash
    local _hf <const> = HASH:init(hashtype)
    return _hf:process(data)
end

-- NOTATION used:
-- data_table = {data1, data2,..}  OCTET form
-- leaves = {hash(data1), hash(data2),..}  HASHTYPE form


-- Function to create a Merkle root from a table of data
-- data table must be OCTET
function MT.create_merkle_root(data_table, hashtype)
    local tree = {}
    -- Hash each piece of data and add to the tree
    for _, data in ipairs(data_table) do
        table.insert(tree, _hash(data, hashtype))
    end
    -- Build the tree by hashing pairs of nodes until a single hash (the root) is obtained
    while #tree > 1 do
        local temp_tree = {}
        for i = 1, #tree, 2 do
            if i + 1 <= #tree then
                local concatenated_hashes = tree[i] .. tree[i + 1]
                table.insert(temp_tree, _hash(concatenated_hashes, hashtype))
            else
                table.insert(temp_tree, tree[i])
            end
        end
        tree = temp_tree
    end
    return tree[1] -- The Merkle root
end

-- data_table must be OCTET
function MT.create_merkle_tree(data_table, hashtype)
    local N = #data_table
    local tree = {}
    -- hashing the data input a filling the end of the tree
    for i = N , 2*N-1 do
        tree[i] = _hash(data_table[ i+1-N ], hashtype)
    end
    -- filling the vector tree: the node in position i has as leafs the nodes in position 2i and 2i+1
    for i = N - 1, 1, -1 do
        local concatenated = tree[ 2*i ] .. tree[ 2*i+1 ]
        tree[i] = _hash(concatenated, hashtype)
    end
    return tree
end

-- The following function is just used for testing test vectors from Frigo's RFC already hashed
-- Here, data_table are the hash of data from the previous functions.
-- In this case, data_table_hashed are already leaves just to insert directley into the tree.
function MT.create_merkle_tree_from_table_of_hashes(data_table_hashed, hashtype)
    local N = #data_table_hashed
    local tree = {}

    --in Frigo's RFC the base leaves are already hashed
    for i = N, 2*N-1 do
        tree[i] = data_table_hashed[ i+1-N ]
    end
    for i = N-1, 1, -1 do
        local concatenated = tree[ 2*i ] .. tree[ 2*i+1 ]
        tree[i] = _hash(concatenated, hashtype)
    end

    return tree
end



function MT.generate_proof(tree, pos)
    local indeces_set = {}
    local N = (#tree+1)/2
    
    -- checking positions of the leaves
    if pos > N then
        error("invalid position for leaf",2)
    end
    
    pos = pos + N - 1

    table.insert(indeces_set, pos)

    while pos > 1 do       
        if pos%2 == 0 then
            table.insert(indeces_set, pos + 1 )
        else
            table.insert(indeces_set, pos - 1 )
        end
        pos = math.floor(pos/2)
    end

    local proof = {}
    local m = #indeces_set

    table.sort(indeces_set)

    for i = 1, m do
        table.insert(proof, tree[indeces_set[i]])
    end

    return proof
end


-- proof is a set of data already hashed since it comes from the tree in the previous function 
-- where all data of the tree are already hashed
-- pos is the position of the leaf to prove in the data_table (not to be considered in the tree).
function MT.verify_proof(proof, pos, root, n , hashtype)
    if n == 1 then
        return proof[1] == root
    end
    
    -- checking positions of the leaves
    if pos > n then
        error("invalid position for leaf",2)
    end
    
    pos = pos + n - 1
    local indeces_set = {}
    table.insert(indeces_set, pos)

    while pos > 1 do        
        if pos%2 == 0 then
            table.insert(indeces_set, pos + 1 )
        else
            table.insert(indeces_set, pos - 1 )
        end
        pos = math.floor(pos/2)
    end

    local set = {}
    local m = #indeces_set

    table.sort(indeces_set)

    for i = 1, m do
        table.insert(set, {proof[i], indeces_set[i]} )
    end

    local n = #proof    
    local t = _hash(set[n-1][1] .. set[n][1], hashtype) 
    
    n = n-2

    while n > 0 do
        if set[n][2]%2 == 1 then
            t = _hash(t .. set[n][1], hashtype)
        else
            t = _hash(set[n][1] .. t, hashtype)
        end
        n = n-1
    end
    
    return t == root
end


function MT.merkle_tree_len(n)
    local r = 0
    local pos = 2*n - 1 
    while pos > 1 do
        r = r + 1
        pos = math.ceil(pos/2)
    end
    return r
end



-- n = number of leaves generating tree
-- pos = table containing positions of the leaves to prove in data_table (not to be considered in the tree)
-- np = number of pos, is #pos (?)
function MT.compressed_merkle_proof_tree(n, pos)
    local np = #pos
    if np < 0 then
        error("A Merkle proof with 0 leaves is not defined.",2)
    end
    --initializing a vector tree[] will contain a boolean (if a leaf of the tree is need or not to create the proof)
    local tree = {}
    for i = 1, 2*n-1 do
        tree[i] = false
    end

    for ip = 1, np do
        if pos[ip] > n then
            error("Invalid position for leaf in Merkle tree",2)
        end
        tree[pos[ip]+n-1] = true   --is a leaf of the tree so it is in the tree and we put its positon in tree[] true
    end

    for i = n-1, 1, -1 do
        tree[i] = tree[2*i] or tree[2*i+1]
    end

    if tree[1] == false then
        error("the root is not in the tree",2)
    end

    return tree
end


-- pos is an array of positions of the leaves to prove: must be position from data_table (or leaves) not from the tree
-- n number of leaves (that are number of data inputs in MT.create_merkle_tree)
function MT.generate_compressed_proof(pos, tree)
    local n = (#tree + 1)/2
    local np = #pos
    local boolean_tree = MT.compressed_merkle_proof_tree(n, pos)
    local proof = {}
    local size = #tree
    -- checking positions of the leaves
    for i = 1, np do
        if pos[i] > n then
            error("invalid position for leaf",2)
        end
    end
    
    for i = n-1, 1, -1 do   --frigo uses n instead of n-1 TO CHECK
        if boolean_tree[i] then
            local child = 2*i
            if boolean_tree[child] == true then
                child = 2*i + 1
            end
            if boolean_tree[child] == false then
                table.insert(proof, tree[child])
            end
        end

    end

    return proof
end

--leaves which are in positions pos from the data_table (is the same in case of leaves already hashed), not all leaves
-- leaves must be already hashed: they are the hash of the input data (octet) of MT.create_merkle_tree
function MT.verify_compressed_proof(proof, leaves, pos, n, root, hashtype )
    local np = #pos

    -- checking positions of the leaves
    for i = 1, np do
        if pos[i] > n then
            error("invalid position for leaf",2)
        end
    end
    
    local tree = {}
    local defined = {}
    for i = 1, 2*n-1 do
        defined[i] = false
    end

    local boolean_tree = MT.compressed_merkle_proof_tree(n , pos)
    local proof_lenght = #proof
    
    local sz = 0    
    for i = n-1, 1, -1 do   --frigo uses n instead of n-1 TO CHECK
        if boolean_tree[i] then
            local child = 2*i
            if boolean_tree[child] == true then
                child = 2*i + 1
            end
            if boolean_tree[child] == false then
                if sz >= proof_lenght then
                    return false
                end
                sz = sz+1
                tree[child] = proof[sz]
                defined[child] = true
            end
        end
    end 

    for ip = 1, np do
        local l = pos[ip] + n - 1
        tree[l] = leaves[ip]
        defined[l] = true
    end

    for i = n-1, 1, -1 do
        if defined[2*i] and defined[2*i+1] then
            tree[i] = _hash(tree[2*i] .. tree[2*i+1], hashtype)
            defined[i] = true
        end
    end

    return defined[1] and tree[1] == root 
end


-- The Following function will be just used for creating a random setting for the verify_compressed_proof in check_merkle_tree
-- n is the number of leaves
-- batch_size the number of leaves to prove
function MT.setup_batch(n, batch_size, hashtype)
    local data = {}
    local leaves = {}
    local pos = {}
    local set = {}
    
    for i = 1, n do
        local leaf = OCTET.from_number(i)
        table.insert(data, leaf)            -- data not alredy hashed
        table.insert(leaves, _hash(leaf, hashtype))   -- leaves have to be hashed
        table.insert(set, i)                -- creating a set where we will extract random indeces in the next step
    end

    local tree = MT.create_merkle_tree(data, hashtype)    
    local leaves_for_proof = {}

    for i = 1, batch_size do
        local random_index = math.random(n+1-i)
        table.insert(pos, set[random_index])   
        table.remove(set, random_index)
    end

    table.sort(pos)     --ordered set of pos of the leaves to take for the proof

    for i = 1, #pos do
        table.insert(leaves_for_proof, leaves[pos[i]])
    end

    return pos, leaves_for_proof, leaves, tree
end

return MT
