--[[
--This file is part of zenroom
--
--Copyright (C) 2025 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Matteo Cristino
--on Thursday, 8th May 2025
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

-- Function to create a Merkle root from a table of data
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
function MT.create_merkle_tree_from_table_of_hashes(data_table, hashtype)
    local N = #data_table
    local tree = {}

    --in Frigo's RFC the base leaves are already hashed
    for i = N, 2*N-1 do
        tree[i] = data_table[ i+1-N ]
    end
    for i = N-1, 1, -1 do
        local concatenated = tree[ 2*i ] .. tree[ 2*i+1 ]
        tree[i] = _hash(concatenated, hashtype)
    end

    return tree
end



--Indeces could have to be shifted
local function _generate_leaves_for_proof1(tree, pos)
    local indeces_set = {}
    pos = pos + N


    table.insert(indeces_set, pos)

    while pos > 2 do
        
        if pos%2 == 0 then
            table.insert(indeces_set, pos - 1 )
        else
            table.insert(indeces_set, pos + 1 )
        end

        pos = math.ceil(pos/2)
    end

    local set = {}
    local m = #indeces_set

    table.sort(indeces_set)

    for i = 1, m do
        set[i] = {tree[indeces_set[i]], indeces_set[i]}
    end

    return set
end



--check the index with official version: could have to be shifted
local function _verify_proof(proof, pos, root, hashtype)
    --local pos = pos + N   -- we can suppose to have N = number of leaves
    local n = #proof
    
    local t = _hash(proof[n-1][1] .. proof[n][1]) 
    n = n-2

    while n > 0 do
        if proof[n][2]%2 == 0 then
            t = _hash(t .. proof[n][1])
        else
            t = _hash(proof[n][1] .. t)
        end
        n = n-1
    end
    
    return t 
    --return t == root
end


return MT
