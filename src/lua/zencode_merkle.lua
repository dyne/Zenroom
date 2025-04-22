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
--on Tuesday, 8th April 2025
--]]

local function _hash(data, hashtype)
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

-- Function to create a Merkle root from a table of data
local function _create_merkle_root(data_table, hashtype)
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

local function _zencode_merkle_root(name, hashtype)
    local data = pick_from_path(name, true)
    if not data or type(data) ~= 'table' then
        error("Table not found in path: "..name, 2)
    end
    ACK.merkle_root = _create_merkle_root(data, hashtype)
    return new_codec('merkle root', {zentype = "string"})
end

When("create merkle root of ''", _zencode_merkle_root)
When("create merkle root of '' using hash ''", _zencode_merkle_root)
When("create merkle root of dictionary path ''", _zencode_merkle_root)
When("create merkle root of dictionary path '' using hash ''", _zencode_merkle_root)

-- Function to verify the integrity of a Merkle root
local function _verify_merkle_root(root, name)
    
    local data_table = pick_from_path(name, true)
    local merkle_root = ACK[root]
    
    if not data_table or not merkle_root then
        error("Inserted values should be not nill", 2)
    end 

    if type(data_table) ~= 'table' then
        error("Table not found in path: "..name, 2)
    end 

    local computed_root = _create_merkle_root(data_table)

    if computed_root ~= merkle_root then
        error("Verification fail: elements are not equal", 2)
    end

    return computed_root == merkle_root
end

When("verify merkle root '' of ''", _verify_merkle_root)
When("verify merkle root '' of dictionary path ''", _verify_merkle_root)



-- Function to create a Merkle tree from a table of data
local function _create_merkle_tree(data_table, hashtype)
    local tree = {}

    -- Hash each piece of data and add to the tree (tree basis leafs)
    for _, data in ipairs(data_table) do
        table.insert(tree, _hash(data, hashtype))
    end

    local temp_tree = tree 

    -- Build the tree by hashing pairs of nodes until a single hash (the root) is obtained
    while #temp_tree > 1 do    
        local temp_tree_step = {}
        for i = 1, #temp_tree, 2 do
            if i + 1 <= #temp_tree then                
                local concatenated_hashes = temp_tree[i] .. temp_tree[i + 1]
                table.insert(tree, _hash(concatenated_hashes, hashtype))
                table.insert(temp_tree_step, _hash(concatenated_hashes, hashtype) )
            else
                table.insert(tree, temp_tree[i])
                table.insert(temp_tree_step, temp_tree[i])    
            end
        end
        temp_tree = temp_tree_step
    end
    
    return tree -- The merkle tree 
    
end


local function _create_merkle_tree2(data_table, hashtype)
    local N = #data_table
    --creation of the empty tree
    local tree = {}
    for i = 1, 2*N do
        tree[i] = "0"
    end

    --hashing the data input a filling the end of the tree
    for i = N + 1, 2*N do
        tree[i] = _hash(data_table[i - N], hashtype)
    end 
    
    --filling the vector tree: the node in position i has as leafs the nodes in position 2i and 2i+1
    for i = N, 2, -1 do
        local concatenated = tree[2*i - 1] .. tree[2*i]
        tree[i] = _hash(concatenated, hashtype)
    end 
    
    return tree
      
end