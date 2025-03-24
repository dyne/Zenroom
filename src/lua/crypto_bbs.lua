--[[
--This file is part of zenroom
--
--Copyright (C) 2023-2024 Dyne.org foundation
--designed and written by Luca Di Domenico, Rebecca Selvaggini and Alberto Lerda
--maintained by Denis Roio
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
--]]

--- <h1>BBS signature scheme</h1>
--
-- The BBS signature scheme (also known as the Boneh-Boyen-Shacham signature scheme) 
-- is a cryptographic signature scheme based on pairing-based cryptography: the BBS scheme is particularly 
-- notable for its use of bilinear pairings on elliptic curves,
-- which enable efficient verification and compact signatures. 
-- It is a probabilistic digital signature scheme based on the discrete logarithm problem, i.e.
-- the difficult of finding the dicrete logarithm in a gruop of prime order.
-- 
-- The BBS signature scheme utilizes two elliptic curves in its construction:
-- E1: y ^ 2 = x ^ 3 + 4 defined over the finite field GF(p). 
--
-- E2: y ^ 2 = x ^ 3 + 4 * (I + 1) where I ^ 2 + 1 = 0 defined over the finite field GF(p^2)
--
-- where p = (t - 1)^2 * (t^4 - t^2 + 1) / 3 + t and t = -2^63 - 2^62 - 2^60 - 2^57 - 2^48 - 2^16.
-- 
-- Let be observed that p is not a prime number and the two subgroups G1 and G2 of E1 and E2 are 
-- the two groups used for the pairing having the same order 
-- r = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001 which is a prime factor of p.
--
-- Public keys and key generation are considered as points in G2 and signatures as point in G1.
-- This choice allows to provide short signatures with strong security guarantees.
-- 
-- 
--
-- @module BBS


-- optimized C extension for map to point
local fastBBS = require("bbs")
local bbs = {}
local OCTET_SCALAR_LENGTH = 32 -- ceil(log2(PRIME_R)/8)
local OCTET_POINT_LENGTH = 48 --ceil(log2(p)/8)

--see draft-irtf-cfrg-bbs-signatures-latest Appendix A.1
local PRIME_R = ECP.order()

--draft-irtf-cfrg-pairing-friendly-curves-11 Section 4.2.1
local IDENTITY_G1 = ECP.generator()

local K = nil -- see function K_INIT() below

-- Added api_id

local CIPHERSUITE_SHAKE = {
    expand = HASH.expand_message_xof,
    ciphersuite_ID = O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_"),
    api_ID =  O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_"),
    generator_seed = O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_MESSAGE_GENERATOR_SEED"),
    seed_dst = O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_SIG_GENERATOR_SEED_"),
    generator_dst = O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_SIG_GENERATOR_DST_"),
    hash_to_scalar_dst = O.from_string('BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_H2S_'),
    map_msg_to_scalar_as_hash_dst = O.from_string('BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_MAP_MSG_TO_SCALAR_AS_HASH_'),
    expand_dst = O.from_string('BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_SIG_DET_DST_'),
    P1 = ECP.from_zcash(O.from_hex('8929dfbc7e6642c4ed9cba0856e493f8b9d7d5fcb0c31ef8fdcd34d50648a56c795e106e9eada6e0bda386b414150755')),
    GENERATORS = {},
    GENERATOR_V = HASH.expand_message_xof(O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_MESSAGE_GENERATOR_SEED"),
    O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_SIG_GENERATOR_SEED_"), 48)
}

local CIPHERSUITE_SHA = {
    expand = HASH.expand_message_xmd,
    ciphersuite_ID = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_"),
    api_ID = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_"),
    generator_seed = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_MESSAGE_GENERATOR_SEED"),
    seed_dst = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_SIG_GENERATOR_SEED_"),
    generator_dst = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_SIG_GENERATOR_DST_"),
    hash_to_scalar_dst = O.from_string('BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_H2S_'),
    map_msg_to_scalar_as_hash_dst = O.from_string('BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_MAP_MSG_TO_SCALAR_AS_HASH_'),
    expand_dst = O.from_string('BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_SIG_DET_DST_'),
    P1 = ECP.from_zcash(O.from_hex('a8ce256102840821a3e94ea9025e4662b205762f9776b3a766c872b948f1fd225e7c59698588e70d11406d161b4e28c9')),
    GENERATORS = {},
    GENERATOR_V = HASH.expand_message_xmd(O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_MESSAGE_GENERATOR_SEED"),
    O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_SIG_GENERATOR_SEED_"), 48)
}
-- Take as input the hash as string and return a table with the corresponding parameters

--- Return a specific ciphersuite based on the provided hash name. 
-- There are two possibilities for the output: the configuration for SHAKE-256 or the configuration for SHA-256.
--
--@function BBS.ciphersuite
--@param hash a string with the name of the hash function, sha256 or shake256
--@return a ciphersuite configuration
--@usage
--bbs = require'crypto_bbs'
--**select the hash sha256
--suite = bbs.ciphersuite('sha256')
--**print for example the ciphersuite ID
--print(suite.ciphersuite_ID)
--**print: BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_
function bbs.ciphersuite(hash_name)
    -- seed_len = 48
    if hash_name:lower() == 'sha256' then
        return CIPHERSUITE_SHA

    elseif hash_name:lower() == 'shake256' then
        return CIPHERSUITE_SHAKE
    else
        error('Invalid hash: use sha256 or shake256', 2)
    end

end


-- RFC8017 section 4
-- converts a nonnegative integer to an octet string of a specified length.
local function i2osp(x, x_len)
    return O.new(BIG.new(x)):pad(x_len)
end

-- RFC8017 section 4
-- converts an octet string to a nonnegative integer.
local function os2ip(oct)
    return BIG.new(oct)
end

-- HASH TO SCALAR FUNCTION

-- It converts a message written in octects into a BIG modulo PRIME_R (order of subgroup)

--[[ 
INPUT: ciphersuite (a table), msg_octects (as zenroom.octet), dst (as zenroom.octet)
OUTPUT: hashed_scalar (as zenroom.BIG), represents an integer between 1 and ECP.order() - 1
]]
local function hash_to_scalar(ciphersuite, msg_octects, dst)
    local BIG_0 = BIG.new(0)
    -- draft-irtf-cfrg-bbs-signatures-latest Section 3.4.3
    local EXPAND_LEN = 48

    -- Default value of DST when not provided (see also Section 6.2.2)
    dst = dst or ciphersuite.hash_to_scalar_dst
    local uniform_bytes = ciphersuite.expand(msg_octects, dst, EXPAND_LEN)
    local hashed_scalar = BIG.mod(uniform_bytes, PRIME_R) -- = os2ip(uniform_bytes) % PRIME_R
    return hashed_scalar
end

-- SECRET KEY GENERATION FUNCTION AND PUBLIC KEY GENERATION FUNCTION

--[[ 
INPUT: key_material, key_info, key_dst (all as zenroom.octet), ciphersuite (as a table that should contained all informations of the
table shown at lines 14 and 30)
OUTPUT: sk (as zenroom.octet), it represents a scalar between 1 and the order of the EC minus 1
]]

---Generate a secret key (sk) for use in cryptographic operations. 
--The function uses a provided ciphersuite, key material, key info, and domain separation tag (DST) to derive the secret key. 
--The ciphersuite is a table containing the cipher suite configuration.
--Key material is an optional input used as the seed for key generation. If not provided, a secure random value of 32 bytes is generated.
--Key info is an optional addition information. If not provided, it defaults to an empty octet. 
--key DST is an optional domain separation tag. If not provided, it defaults to the ciphersuite's ciphersuite\_ID concatenated with the string 'KEYGEN\_DST\_'.
--
--@function BBS.keygen
--@param ciphersuite 
--@param key_material
--@param key_info 
--@param key_dst
--@return sk, a private key 32 bytes long
--@usage 
--bbs = require'crypto_bbs'
--**generate ciphersuite and  key_m, key_info, key_dst as random octet of 32 bytes
--ciphersuite = bbs.ciphersuite('sha256') 
--key_material = O.random(32)
--key_info = O.random(32)
--key_dst = O.randopm(32)
--**calculate the private key
--sk = bbs.keygen(ciphersuite, key_material, key_info, key_dst)

function bbs.keygen(ciphersuite, key_material, key_info, key_dst)
    key_material = key_material or O.random(32) -- O.random is a secure RNG.
    if not ciphersuite then
        error('Ciphersuite not initialized in BBS.keygen',2)
    end
    -- TODO: add warning on curve must be BLS12-381
    if not key_info then
        key_info = O.empty()
    elseif type(key_info) == 'string' then
        key_info = O.from_string(key_info)
    end
    if not key_dst then
        key_dst = ciphersuite.ciphersuite_ID .. O.from_string('KEYGEN_DST_')
    elseif type(key_info) == 'string' then
        key_dst = O.from_string(key_info)
    end
    if #key_material < 32 then error('INVALID',2) end
    if #key_info > 65535 then error('INVALID',2) end

    -- using BLS381
    -- 254 < log2(PRIME_R) < 255
    -- ceil((3 * ceil(log2(PRIME_R))) / 16)
    local derive_input = key_material .. i2osp(#key_info,2) .. key_info
    local sk = hash_to_scalar(ciphersuite, derive_input, key_dst)

    return sk
end

function bbs.sk2pk(sk)
    return (ECP2.generator() * sk):to_zcash()
end

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------

-- THE FOLLOWING MULTI-LINE COMMENT CONTAINS GENERIC VERSIONS OF THE hash_to_field function.

-- draft-irtf-cfrg-hash-to-curve-16 section 5.2
--it returns u a table of tables containing big integers representing elements of the field
--[[
function bbs.hash_to_field(msg, count, DST)
    -- draft-irtf-cfrg-hash-to-curve-16 section 8.8.1 (BLS12-381 parameters)
    -- BLS12381G1_XMD:SHA-256_SSWU_RO_
    local m = 1
    local L = 64

    local len_in_bytes = count*m*L
    local uniform_bytes = HASH.expand_message_xmd(msg, DST, len_in_bytes)
    local u = {}
    for i = 0, (count-1) do
        local u_i = {}
        for j = 0, (m-1) do
            local elm_offset = L*(j+i*m)
            local tv = uniform_bytes:sub(elm_offset+1,L+elm_offset)
            local e_j = BIG.mod(tv, p) --local e_j = os2ip(tv) % p
            u_i[j+1] = e_j
        end
        u[i+1] = u_i
    end

    return u
end

--hash_to_field CASE m = 1
function bbs.hash_to_field_m1(msg, count, DST)
    -- draft-irtf-cfrg-hash-to-curve-16 section 8.8.1 (BLS12-381 parameters)
    -- BLS12381G1_XMD:SHA-256_SSWU_RO_
    local L = 64

    local len_in_bytes = count*L
    local uniform_bytes = HASH.expand_message_xmd(msg, DST, len_in_bytes)
    local u = {}
    for i = 0, (count-1) do
        local elm_offset = L*i
        local tv = uniform_bytes:sub(elm_offset+1,L+elm_offset)
        u[i+1] = BIG.mod(tv, p) --local e_j = os2ip(tv) % p
    end

    return u
end
--]]

-- draft-irtf-cfrg-hash-to-curve-16 section 5.2
-- It returns u a table of tables containing big integers representing elements of the field (SPECIFIC CASE m = 1, count = 2)

---Hash a message into two field elements in the prime field of an elliptic curve.
--This is a common operation in cryptographic protocols,  
--where messages need to be mapped to field elements.
--The third input of the function, the domain separation tag, ensures that the same input message can be hashed differently 
--for different purposes, preventing collisions or unintended reuse of hash outputs.
--
--@function BBS.hash_to_field_m1_c2
--@param ciphersuite
--@param msg the input message to be hashed
--@param dst a domain separation tag
--@return a table containing the two field elements
--@usage 
--bbs = require'crypto_bbs'
--**define a ciphersuite, a DST and a random message
--ciphersuite = bbs.ciphersuite('sha256') 
--DST_hash_to_field = 'QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_'
--msg = O.random(32)
--**return the table H. H[1] and H[2] will be the two field elements
--H = bbs.hash_to_field_m1_c2(ciphersuite, msg, DST_hash_to_field)

function bbs.hash_to_field_m1_c2(ciphersuite, msg, dst)
    local p = ECP.prime()
    local L = 64

    local uniform_bytes = ciphersuite.expand(msg, dst, 2*L)
    local u = {}
    u[1] = BIG.mod(uniform_bytes:sub(1,L), p)
    u[2] = BIG.mod(uniform_bytes:sub(L+1,2*L), p)
    return u
end


-- draft-irtf-cfrg-hash-to-curve-16 Section 7
-- It returns a point in the correct subgroup.
local function clear_cofactor(ecp_point)
    local h_eff = BIG.new(O.from_hex('d201000000010001'))
    return ecp_point * h_eff
end

--HASH TO CURVE AND CREATE GENERATORS ARE VERY SLOW, MAYBE BETTER TO IMPLEMENT SOMETHING IN C SEE https://github.com/dyne/Zenroom/issues/642  
-- draft-irtf-cfrg-hash-to-curve-16 Section 3
-- It returns a point in the correct subgroup.

---Hash a message to a point on an elliptic curve. This is a common operation in cryptographic protocols, where messages 
--need to be mapped to curve points for operations like signing and verification.
--It uses @{hash_to_field_m1_c2} function to hash the message into two field elements 
--that are mapped to a point on the elliptic curve.
--
--@function BBS.hash_to_curve
--@param ciphersuite 
--@param msg the input message to be hashed
--@param dst a domain separation tag
--@return the final curve point after clearing the cofactor
--@usage 
--bbs = require'crypto_bbs'
--**define a ciphersuite, a DST and a random message
--ciphersuite = bbs.ciphersuite('sha256') 
--DST_hash_to_field = 'QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_'
--msg = O.random(32)
--**return the curve point
--P = bbs.hash_to_curve(ciphersuite, msg, DST_hash_to_field)

function bbs.hash_to_curve(ciphersuite, msg, dst)
    -- local u = bbs.hash_to_field_m1(msg, 2, DST)
    local p = ECP.prime()
    local u = bbs.hash_to_field_m1_c2(ciphersuite, msg, dst)
    local Q0 = fastBBS.map_to_curve(u[1])
    local Q1 = fastBBS.map_to_curve(u[2])
    return clear_cofactor(Q0 + Q1)
end

--draft-irtf-cfrg-bbs-signatures Section 4.2
--It returns an array of generators.

---Create a set of cryptographic generators. 
--These generators are points on an elliptic curve and are used in operations like signing and verification. 
--The function ensures that the generators are created deterministically and securely, 
--based on a seed value and domain separation tags.
--
--@function BBS.create_generators
--@param ciphersuite
--@param count the number of generators to create
--@return the first 'count' generators from the ciphersuite.GENERATORS table
--@usage
--bbs = require'crypto_bbs'
--**define a ciphersuite and a count
--ciphersuite = bbs.ciphersuite('sha256') 
--count = 5
--**return a table G of 5 generators
--G = bbs.create_generators(ciphersuite,count)

function bbs.create_generators(ciphersuite, count)
    if count > 2^64 -1 then error("Message's number too big. At most 2^64-1 message allowed") end

    if #ciphersuite.GENERATORS < count then
        -- local seed_len = 48 --ceil((ceil(log2(PRIME_R)) + k)/8)
        local v = ciphersuite.GENERATOR_V

        for i = #ciphersuite.GENERATORS + 1, count do
            v = ciphersuite.expand(v..i2osp(i,8), ciphersuite.seed_dst, 48)
            local generator = bbs.hash_to_curve(ciphersuite, v, ciphersuite.generator_dst)
            table.insert(ciphersuite.GENERATORS, generator)
        end

        ciphersuite.GENERATOR_V = v
        return ciphersuite.GENERATORS
    else
        return {table.unpack(ciphersuite.GENERATORS, 1, count)}
    end
end


--[[ 
DESCRIPTION: the function bbs.messages_to_scalars is the new version of the function bbs.MapMessageToScalarAsHash.
The main difference is that in the new verison we can transform a set of messages into a scalar instead of transforming one message.
INPUT: messages (a vector of zenroom.octet where index starts from 1), api_id (as zenroom.octet) which FOR NOW is stored in the ciphersuite for simplicity.
OUTPUT: msg_scalars (a vector of scalars stored as zenroom.octet)
]]

---Convert a list of messages, a vector of octets, into a list of scalar values using a cryptographic hash function.
--
--@function BBS.messages_to_scalars
--@param ciphersuite
--@param messages a set of messages
--@return a vector of scalars stored as octet
--@usage 
--bbs = require'crypto_bbs'
--**define a ciphersuite and a set of random messages
--ciphersuite = bbs.ciphersuite('sha256') 
--map_messages_to_scalar_messages = {
--    O.random(32),
--    O.random(64),
--    O.random(16)  
--}
--**return a vector of octets
--output_scalar = bbs.messages_to_scalars(ciphersuite,map_messages_to_scalar_messages)

function bbs.messages_to_scalars(ciphersuite, messages)

    local L = table_size(messages)

    -- for now api_id is in the ciphersuite so we already know it is always given as input since ciphersuite is always given
    -- later we may add a check: if api_id is unknown use an empty string

    local msg_scalars = {}

    for i = 1, L do
        msg_scalars[i] = hash_to_scalar(ciphersuite,messages[i],ciphersuite.map_msg_to_scalar_as_hash_dst)
    end

    return msg_scalars

end

--[[
DESCRIPTION: The following function takes in input an array of elements that can be points on the EC (as zenroom.ecp or zenroom.ecp2),
    big integers (as zenroom.big) and integers (as number). It converts each element of the array into an octet string (zenroom.octet) and
    output the concatenation of all such strings.
    INPUT: array of elements in "zenroom.ecp", "zenroom.ecp2", "zenroom.big" or "number"
    OUTPUT: octet_result as "zenroom.octet"
]]
local function serialization(input_array)
    local octet_result = O.empty()
    local el_octs = O.empty()
    for i=1, table_size(input_array) do
        local elt = input_array[i]
        local elt_type = type(elt)
        if (elt_type == "zenroom.ecp") or (elt_type == "zenroom.ecp2") then
            el_octs = elt:to_zcash()
        elseif (elt_type == "zenroom.big") then
            el_octs = i2osp(elt, OCTET_SCALAR_LENGTH)
        elseif (elt_type == "number") then
            el_octs = i2osp(elt, 8)
        else
            error("Invalid type passed inside serialize", 4)
        end

        octet_result = octet_result .. el_octs

    end

    return octet_result
end

--[[
DESCRIPTION: It calculates a domain value, distillating all essential contextual information for a signature.
INPUT: PK (as zenroom.octet) representing the public key, Q1 (as zenroom.ecp) representing a point on the EC, H_points (an array of points
on the subgroup stored as zenroom.ecp), header (as zenroom.octet)
OUTPUT: a scalar represented as zenroom.octet
]]
local function calculate_domain(ciphersuite, pk_octet, Q1, H_points, header)

    header = header or O.empty()

    local len = #H_points
    -- assert(#(header) < 2^64)
    -- assert(L < 2^64)

    local dom_array = {len, Q1, table.unpack(H_points)}
    local dom_octs = serialization(dom_array) .. ciphersuite.api_ID
    local dom_input = pk_octet .. dom_octs .. i2osp(#header, 8) .. header
    local domain = hash_to_scalar(ciphersuite, dom_input,ciphersuite.hash_to_scalar_dst)

    return domain
end

--[[
DESCRIPTION:  This operation computes a deterministic signature from a secret key(SK), a set of generators (points of G1) and
optionally a header and a vector of messages.
INPUT: ciphersuite, SK as (zenroom.octet), PK (as zenroom.octet) representing the public key, messages( an array of scalars representing the messages,
stored as zenroom.big), generators ( an array of points on the subgroup of EC1 stored as zenroom.ecp), header (as zenroom.octet)
OUTPUT: a pair (A,e) represented as zenroom.octet
]]
local function core_sign(ciphersuite, sk, pk, header, messages, generators)

    -- Deserialization
    local LEN = #messages
    if (#generators ~= (LEN +1)) then
        error("The numbers of generators must be #messages +1",3)
    end

    local Q_1 = generators[1]
    local H_array = { table.unpack(generators, 2, LEN + 1) }

    --Procedure
    local domain = calculate_domain(ciphersuite, pk , Q_1, H_array, header)
    local serialize_array = {sk, table.unpack(messages)}
    table.insert(serialize_array, domain)
    local e = hash_to_scalar(ciphersuite, serialization(serialize_array))

    local BB = ciphersuite.P1 + Q_1* domain
    if (LEN > 0) then
        for i = 1,LEN do
            BB = BB + (H_array[i]* messages[i])
        end
    end
    if (BIG.mod(sk + e, PRIME_R) == BIG.new(0))  then
        error("Invalid value for e",3)   
    end
    local AA = BB * BIG.moddiv(BIG.new(1), sk + e, PRIME_R)
    return serialization({AA, e})
end


--[[
DESCRIPTION: The Sign operation returns a BBS signature from a secret key (SK), over a header and a set of messages.
INPUT: ciphersuite , sk (as zenroom.octet), pk (as zenroom.octet), header (as zenroom.octet), messages (array of octet strings stored as zenroom.octet),
header (as zenroom.octet).
OUTPUT: the signature (A,e)
]]

---The Sign operation returns a BBS signature from a secret key (sk), over a header and a set of messages. 
--It uses the <code>core_sign</code> function, that computes a deterministic signature from a secret key (sk), a set of generators (points of G1) 
--and optionally a header and a vector of messages.
--
--@function BBS.sign
--@param ciphersuite 
--@param sk the secret key as an octet
--@param header
--@param messages array of octet strings stored as octet
--@return the signature 
--@usage 
--bbs = require'crypto_bbs'
--**define a ciphersuite, a secret key, a public key, an header and a message 
--ciphersuite = bbs.ciphersuite('sha256') 
--SECRET_KEY = "60e55110f76883a13d030b2f6bd11883422d5abde717569fc0731f51237169fc"
--HEADER = "11223344556677889900aabbccddeeff"
--SINGLE_MSG_ARRAY = { O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
--**calculate the signature for the given message
--output_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(HEADER), SINGLE_MSG_ARRAY)


function bbs.sign(ciphersuite, sk, header, messages_octets)

    -- Default values for header and messages.
    if not messages_octets then
            error('Empty message argument in BBS.sign',2)
    end
    local pk = bbs.sk2pk(sk)
    header = header or O.empty()
    local messages = bbs.messages_to_scalars(ciphersuite,messages_octets)

    local generators = bbs.create_generators(ciphersuite, #messages +1)
    local signature = core_sign(ciphersuite, sk, pk, header, messages, generators)
    return signature

end

--draft-irtf-cfrg-bbs-signatures Section 4.7.3
-- It is the opposite function of "serialize" with input "(POINT, SCALAR, SCALAR)"
local function octets_to_signature(signature_octets)
    local expected_len = OCTET_SCALAR_LENGTH + OCTET_POINT_LENGTH
    if (#signature_octets ~= expected_len) then
        error("Wrong length of signature_octets", 4)
    end
    local A_octets = signature_octets:sub(1, OCTET_POINT_LENGTH)
    local AA = ECP.from_zcash(A_octets:octet())
    if (AA == IDENTITY_G1) then
        error("Point is identity", 4)
    end

    local index = OCTET_POINT_LENGTH + 1
    local end_index = index + OCTET_SCALAR_LENGTH - 1
    -- os1ip transform a string into a BIG
    local s = os2ip(signature_octets:sub(index, end_index))
    if (s == BIG.new(0)) or (s >= PRIME_R) then
        error("Wrong s in deserialization", 4)
    end

    return {AA, s}
end

--draft-irtf-cfrg-bbs-signatures Section 4.7.6

---Ensure that the public key is valid, in the right subgroup, and not the identity element.
--It converts the public key (pk) into a point W on the elliptic curve in G2 and checks if W is in the correct subgroup.
--
--@function BBS.octets_to_pub_key
--@param pk the public key
--@return the point W 
--@usage 
--bbs = require'crypto_bbs'
--**define a ciphersuite and a public key
--ciphersuite = bbs.ciphersuite('sha256') 
--PUBLIC_KEY = "a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d
--              91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c"
--**calculate the point W
--W = bbs.octets_to_pub_key(O.from_hex(PUBLIC_KEY))

function bbs.octets_to_pub_key(pk)
    local W = ECP2.from_zcash(pk)

    -- ECP2.infinity == Identity_G2
    if (W == ECP2.infinity()) then
        error("W is identity G2", 4)
    end
    if (W * PRIME_R ~= ECP2.infinity()) then
        error("W is not in subgroup", 4)
    end

    return W
end


--[[
DESCRIPTION: Given the signature, the set of messages associated and the public key, the following function verify if the signature is valid
INPUT: ciphersuite (a table), pk (as zenroom.octet), signature (as zenroom.octet), generators (array of points on the subgroup of EC1 as
zenroom.ecp), messages (array of scalars stored as zenroom.octet), header (as zenroom.octet).
OUTPUT: a boolean, true or false 
]]
local function core_verify(ciphersuite, pk, signature, generators, messages, header)

    -- Default values
    header = header or O.empty()

    -- Deserialization
    local signature_result = octets_to_signature(signature) -- transform octet into a table {AA, s}: with entries in zenroom.ecp and zenroom.BIG
    local AA, s = table.unpack(signature_result)
    local W = bbs.octets_to_pub_key(pk)
    local LEN = #messages
    local Q_1 = table.unpack(generators, 1)
    local H_points = { table.unpack(generators, 2, LEN + 1) }
    -- Procedure
    local domain = calculate_domain(ciphersuite, pk, Q_1, H_points, header)
    local BB = ciphersuite.P1 + (Q_1 * domain)
    if (LEN > 0) then
        for i = 1, LEN do
            BB = BB + (H_points[i] * messages[i])
        end
    end
    local LHS = ECP2.ate(W + (ECP2.generator() * s), AA)
    local RHS = ECP2.ate(ECP2.generator(), BB)
    return LHS == RHS
end


--[[
DESCRIPTION: The Verify operation validates a BBS signature, given a public key (PK), a header and a set of messages.
INPUT: ciphersuite (a table), pk (as zenroom.octet), signature (as zenroom.octet), messages (array of octet strings as zenroom.octet), header (as zenroom.octet).
OUTPUT: a boolean, true or false 
]]

---Validate a BBS signature. To do this it uses the <code>core_verify</code> function, which verify if the signature is valid.
--
--@function BBS.verify
--@param ciphersuite
--@param pk the public key as an octet
--@param signature as an octet 
--@param header
--@param messages an array of octet strings as octet
--@return a boolean, true if the signature is valid, false otherwise
--@usage 
--**from the usage in the sign function, check if the signature is valid
--if bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_signature, O.from_hex(HEADER), SINGLE_MSG_ARRAY) then print ("valid signature")
--else print("invalid signature")
--end
--**print:valid signature

function bbs.verify(ciphersuite, pk ,signature, header, messages_octets)
    messages_octets = messages_octets or O.empty{}
    local messages = bbs.messages_to_scalars(ciphersuite,messages_octets)
    local generators = bbs.create_generators(ciphersuite, #messages +1)
    return core_verify(ciphersuite, pk,signature, generators, messages, header)
end



--[[
---------------------------------
-- Credentials:ProofGen,ProofVerify -------
---------------------------------
---------------------------------
---------------------------------
---------------------------------
---------------------------------
]]

-- draft-irtf-cfrg-bbs-signatures-latest Section 4.1
-- It returns count random scalar.

---Generate a table of random scalars that are uniformly distributed modulo the ECP order.
--
--@function BBS.calculate_random_scalars
--@param count number of random scalars to generate
--@return a table of uniformly distributed random scalars modulo the ECP order
--@usage 
--**generate a table of 5 random scalars
--T = bbs.calculate_random_scalars(5)

function bbs.calculate_random_scalars(count)
    local scalar_array = {}
    --[[ This does not seem uniformly random:
    for i = 1, count do
        scalar_array[i] = BIG.mod(O.random(48), PRIME_R)
    end
    --]]
    -- We leave it like this because it should yield a more uniform distribution.
    for i=1,count do
        local scalar = os2ip(BIG.random())
        while scalar > PRIME_R do
            scalar = os2ip(BIG.random())
        end
        table.insert(scalar_array, scalar)
    end
    return scalar_array
end

--[[
DESCRIPTION: This function calculates the challange scalar value needed for both the CoreProofGen and the CoreProofVerify
INPUT: ciphersuite (a table), init_res (a vector consisting of five points of G1 and a scalar value in that order), disclosed_messages (vector of scalar values), 
disclosed_indexes (vector of non-negative integers in ascending order), ph( an octet string)

OUTPUT: challenge, a scalar
]]

local function proof_challenge_calculate(ciphersuite, init_res, disclosed_messages, disclosed_indexes, ph)
    
    ph = ph or O.empty()

    local R_len = #disclosed_indexes
    -- We avoid the check R_len < 2^64
    if R_len ~= #disclosed_messages then
        error("disclosed_indexes length is not equal to disclosed_me length", 4)
    end
    -- We avoid the check #(ph) < 2^64
    local c_array = {}

    if R_len ~= 0 then
        c_array = {R_len}       
        for i = 1, R_len do
            table.insert(c_array, disclosed_indexes[i]-1)
            table.insert(c_array, disclosed_messages[i])
        end
        for i = 1, 6 do
           table.insert(c_array,init_res[i])
        end
    else
        c_array = {R_len, table.unpack(init_res,1,6)}
    end
    local c_octs = serialization(c_array) .. i2osp(#ph, 8) .. ph
    

    local challenge = hash_to_scalar(ciphersuite, c_octs)

    return challenge
end

--[[
INPUT: pk (zenroom.octet), signature_result (a pair zenroom.ecp, zenroom.BIG), generators (vector of points of G1 in zenroom.ecp),
random_scalars (vector zenroom.BIG) header (zenroom.octet), messages (vector of scalars in zenroom.BIG), undisclosed_indexes (vector of numbers),
ciphersuite (table).
OUTPUT: init_res a table with 5 points on G1 (zenroom.ecp) and a scalar (zenroom.BIG)
]]

local function proof_init(ciphersuite, pk, signature_result, generators, random_scalars, header, messages, undisclosed_indexes)
    local AA, e = table.unpack(signature_result)
    local L = table_size(messages)
    local U = table_size(undisclosed_indexes)
    local j = {table.unpack(undisclosed_indexes)}
    local r1, r2, et, r1t, r3t = table.unpack(random_scalars,1,5)
    local mjt = {table.unpack(random_scalars, 6, 5 + U)}

    if table_size(generators) ~= L+1 then error('Wrong generators length') end
    local Q_1 = table.unpack(generators, 1)
    local MsgGenerators = {table.unpack(generators, 2, 1 + L)}
    local H_j = {}
    for i = 1, U do
        H_j[i] = MsgGenerators[j[i]]
    end
    
    if U > L then error('number of undisclosed indexes is bigger than the number of messages', 4) end
    for i = 1, U do
        if undisclosed_indexes[i] <= 0 or undisclosed_indexes[i] > L then error('Wrong undisclosed indexes', 4) end
    end
    
    local domain = calculate_domain(ciphersuite, pk, Q_1, MsgGenerators, header)
    
    local BB = ciphersuite.P1 + (Q_1 * domain)
    for i = 1, L do
        BB = BB + (MsgGenerators[i] * messages[i])
    end
    
    local D = BB * r2
    local Abar = AA * (r1 * r2)
    local Bbar = (D * r1) - (Abar * e)
    local T1 = (Abar * et) + (D * r1t)
    local T2 = (D * r3t)
    for i = 1, U do
        T2 = T2 + (H_j[i] * mjt[i])
    end
    local init_res = {Abar, Bbar, D, T1, T2, domain}
    return init_res

end

--[[
INPUT: init_res (output of ProofInit), challenge (output of ProofChallengeCalculate), e_value (scalar zenroom.BIG), random_scalars (vector of
scalars, zenroom.BIG), undisclosed_messages (vector of scalars, zenroom.BIG)
OUTPUT:
]]

local function proof_finalize(init_res, challenge, e_value, random_scalars, undisclosed_messages)
    local U = table_size(undisclosed_messages)

    if table_size(random_scalars) ~= U + 5 then error('Wrong number of random scalars', 4) end
    
    local r1, r2, et, r1t, r3t = table.unpack(random_scalars,1,5)

    local mjt = {table.unpack(random_scalars, 6, 5 + U)}
    

    local Abar, Bbar, D = table.unpack(init_res)
    local r3 = BIG.moddiv(BIG.new(1), r2, PRIME_R)
    local es = BIG.mod(et + BIG.modmul(e_value, challenge, PRIME_R),PRIME_R)
    local r1s = BIG.mod(r1t - BIG.modmul(r1, challenge,PRIME_R),PRIME_R)
    local r3s = BIG.mod(r3t - BIG.modmul(r3,challenge,PRIME_R),PRIME_R)
    local ms = {}
    for j = 1, U do
        ms[j] = BIG.mod(mjt[j] + (undisclosed_messages[j] * challenge), PRIME_R)
    end
    local proof = {Abar, Bbar, D, es, r1s, r3s} --ms, challenge
    for i = 1, U do
        proof[6 + i] = ms[i]
    end
    proof[6 + U + 1] = challenge
    return serialization(proof)
end

--[[
INPUT: ciphersuite (table), pk (zenroom.octet), signature (zenroom.octet), generators (vector of zenroom.ecp on G1), header (zenroom.octet),
ph (zenroom.octet), messages (vector of scalars in zenroom.BIG), disclosed_indexes (vector of numbers)
OUTPUT: proof (output of ProofFinalize)
]]

local function core_proof_gen(ciphersuite, pk, signature, generators, header, ph, messages, disclosed_indexes)
    local L = table_size(messages)
    local R = table_size(disclosed_indexes)
    if R > L then error('number of disclosed indexes is bigger than the number of messages', 3) end
    local U <const> = L - R
    local signature_result = octets_to_signature(signature)
    local AA, e = table.unpack(signature_result)
    local undisclosed_indexes = {}
    local disclosed_messages = {}
    local undisclosed_messages = {}
    for i, v in ipairs(disclosed_indexes) do
        if i > 1 and disclosed_indexes[i] == disclosed_indexes[i - 1] then --Arrays are always sorted in proof_gen (line 684) before being passed as input to core_proof_gen
            error('disclosed indexes contains duplicates', 3)
        end
        table.insert(disclosed_messages, messages[v])
    end
    for i = 1, L do
        if not array_contains(disclosed_indexes, i) then
            table.insert(undisclosed_indexes, i)
        end
    end
    for _,v in ipairs(undisclosed_indexes) do
        table.insert(undisclosed_messages, messages[v])
    end

    local random_scalars <const> = bbs.calculate_random_scalars(5 + U)

    local init_res = proof_init(ciphersuite, pk, signature_result, generators, random_scalars, header, messages, undisclosed_indexes)
    
    local challenge =  proof_challenge_calculate(ciphersuite, init_res, disclosed_messages, disclosed_indexes, ph)
    
    local proof = proof_finalize(init_res, challenge, e, random_scalars, undisclosed_messages)

    return proof
end

--[[
INPUT: ciphersuite (table), pk (zenroom.octet), signature (zenroom.octet), header (zenroom.octet), ph (zenroom.octet), messages (vector of
zenroom.octet), disclosed_indexes (vector of number)
OUTPUT: proof (output of CoreProofGen)
]]

---Allow a user to prove knowledge of a valid signature while selectively revealing some messages and keeping others hidden.
--It uses other functions during the process. In particular, the <code>proof\_init()</code> function constructs commitments using the signature, public key, message generators, and random scalars.
--The <code>proof\_challenge\_calculate</code> function generates a challenge value from the commitments. The <code>proof\_finalize</code> function 
--computes the final proof values based on the challenge and initial commitments.
--
--@function BBS.proof_gen
--@param ciphersuite
--@param pk the public key
--@param signature
--@param header
--@param ph the presentation header
--@param messages an array of messages
--@param indexes an array of indexes of messages the prover wants to reveal
--@return a zero-knowledge proof that can be verified without revealing the entire signature.
--@usage 
--bbs = require'crypto_bbs'
--**define ciphersuite, sk, pk, header, single message array, presentation header and calculate a valid signature
--ciphersuite = bbs.ciphersuite('sha256') 
--SECRET_KEY = "60e55110f76883a13d030b2f6bd11883422d5abde717569fc0731f51237169fc"
--PUBLIC_KEY = "a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7
--              632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c"
--HEADER = "11223344556677889900aabbccddeeff"
--SINGLE_MSG_ARRAY = { O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
--PRESENTATION_HEADER = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")
--output_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), SINGLE_MSG_ARRAY)
--**return the proof like an octet
--pg_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), output_signature, O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})

function bbs.proof_gen(ciphersuite, pk, signature, header, ph, messages, disclosed_indexes)
    header = header or O.empty()
    ph = ph or O.empty()
    table.sort(disclosed_indexes) -- make sure indexes are sorted
    if disclosed_indexes[1] <= 0 then
        error('Disclosed indexes contains an integer less than or equal to 0', 2)
    end
    if disclosed_indexes[#disclosed_indexes] > #messages then
        error('Disclosed index contains an integer which exceeds the total  number of messages', 2)
    end
    local messages = bbs.messages_to_scalars(ciphersuite,messages)
    local generators = bbs.create_generators(ciphersuite, table_size(messages) + 1)
    local proof = core_proof_gen(ciphersuite, pk, signature, generators, header, ph, messages, disclosed_indexes)

    return proof
end

--[[
DESCRIPTION: Decode an octet string representing the proof
INPUT: proof_octets (an octet string)
OUTPUT: proof ( an array of 3 points of G1 and 4 + U scalars)
]]
local function octets_to_proof(proof_octets)
    local proof_len_floor = 3*OCTET_POINT_LENGTH + 4*OCTET_SCALAR_LENGTH
    if #proof_octets < proof_len_floor then
        error("proof_octets is too short", 4)
    end
    local index = 1
    local return_array = {}
    for i = 1, 3 do
        local end_index = index + OCTET_POINT_LENGTH - 1
        return_array[i] = ECP.from_zcash(proof_octets:sub(index, end_index))
        if return_array[i] == IDENTITY_G1 then
            error("Invalid point", 4)
        end
        index = index + OCTET_POINT_LENGTH
    end

    local j = 4
    while index < #proof_octets do
        local end_index = index + OCTET_SCALAR_LENGTH -1
        return_array[j] = os2ip(proof_octets:sub(index, end_index))
        if (return_array[j] == BIG.new(0)) or (return_array[j]>=PRIME_R) then
            print(j)
            error("Not a scalar in octets_to_proof", 4)
        end
        index = index + OCTET_SCALAR_LENGTH
        j = j+1
    end

    if index ~= #proof_octets +1 then
        error("Index is not right length", 4)
    end

    local msg_commitments = {}
    if j > 7 then
        msg_commitments = {table.unpack(return_array, 7, j-2)}
    end
    local ret_array = {table.unpack(return_array, 1, 6)}
    ret_array[7] = msg_commitments
    table.insert(ret_array,return_array[j-1])
    return ret_array

end

--[[
DESCRIPTION: This operations initializes the proof verification and return one of the inputs of the challenge calculation operation 
INPUT: ciphersuite (a table), pk (as zenroom.octet), Abar, Bbar, D (G1 points), ehat, r1hat ,r3hat (scalars), commitments (a scalar vector), c(a scalar)
generators ( an array of G1 points), header (as zenroom.octet), disclosed_messages (array of octet strings), disclosed_indexes( an array of positive integers) .
OUTPUT: an array consisting of 4 G1 points and a scalar   
]]
local function proof_verify_init(ciphersuite, pk, Abar, Bbar, D , ehat, r1hat, r3hat , commitments, c, generators, header, disclosed_messages, disclosed_indexes)

    local len_U = table_size(commitments)
    local len_R = table_size(disclosed_indexes)
    local len_L = len_R + len_U

    --Preconditions
    for _,i in pairs(disclosed_indexes) do
        if (i < 1) or (i > len_L) then
            error("disclosed_indexes out of range", 4)
        end
    end
    if table_size(disclosed_messages) ~= len_R then
        error("Unmatching indexes and messages", 4)
    end

    local Q_1 = generators[1]
    local MsgGenerators = {table.unpack(generators, 2, len_L+1)}

    local disclosed_H = {}
    local secret_H = {}
    for i = 1, len_L do
        if array_contains(disclosed_indexes,i) then
            table.insert(disclosed_H, MsgGenerators[i])
        else
            table.insert(secret_H, MsgGenerators[i])
        end
    end

    local domain = calculate_domain(ciphersuite, pk, Q_1, MsgGenerators, header)

    local T_1 = Bbar* c + Abar* ehat + D* r1hat
 
    local Bv = ciphersuite.P1 + Q_1*domain
    for i = 1, len_R do
        Bv = Bv + disclosed_H[i]*disclosed_messages[i]
    end

    local T_2 = Bv*c + D* r3hat
    for i = 1, len_U do
        T_2 = T_2 + secret_H[i]*commitments[i]
    end
    return {Abar, Bbar, D, T_1, T_2, domain}


end

--[[
DESCRIPTION: This operations checks the validity of the proof
INPUT: ciphersuite (a table), pk (as zenroom.octet), proof (as zenroom.octet), generators ( an array of G1 points), header (as zenroom.octet), ph( as zenroom.octet)
disclosed_messages (array of octet strings), disclosed_indexes( an array of positive integers) .
OUTPUT: a boolean true or false   
]]
local function core_proof_verify(ciphersuite, pk , proof, generators, header, ph, disclosed_messages, disclosed_indexes)

    local proof_result = octets_to_proof(proof)
    local Abar, Bbar, D , ehat, r1hat, r3hat , commitments, cp = table.unpack(proof_result)
    local W = bbs.octets_to_pub_key(pk)

    local init_res = proof_verify_init(ciphersuite, pk , Abar, Bbar, D , ehat, r1hat, r3hat , commitments, cp, generators, header, disclosed_messages, disclosed_indexes)
    local challenge = proof_challenge_calculate(ciphersuite, init_res, disclosed_messages, disclosed_indexes, ph)
    if (cp ~= challenge) then
        return false
    end

    local LHS = ECP2.ate(W, Abar)
    local RHS = ECP2.ate(ECP2.generator(), Bbar)
    return  LHS == RHS

end

--[[
DESCRIPTION: This function validates a BBS proof
INPUT: ciphersuite (a table), pk (as zenroom.octet), proof (as zenroom.octet), header (as zenroom.octet), ph( as zenroom.octet)
disclosed_messages (array of octet strings), disclosed_indexes( an array of positive integers) .
OUTPUT: a boolean true or false   
]]

---It is responsible for validating a BBS proof. This proof was generated by @{proof_gen} and allows a verifier to confirm that a signer possesses a valid BBS 
--signature while selectively revealing only some signed messages.
--It uses some other functions: the <code>octets\_to\_proof</code> function converts the proof octet string into its mathematical components (group elements and scalars).
--The <code>proof\_verify\_init</code> function computes the expected commitments for disclosed and undisclosed messages.
--The <code>proof\_challenge\_calculate</code> ensures that the challenge scalar was computed correctly.
--
--@function BBS.proof_verify
--@param ciphersuite
--@param pk the public key
--@param header
--@param ph the presentation header
--@param messages an array of messages
--@param indexes an rray of indexes specifying which messages were disclosed
--@return true if the proof is valid, false otherwise
--@usage 
--**from the usage in the proof_gen function, check if the proof is valid
--if  bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}) then print("valid proof")
--else print("invalid proof")
--end
--**print: valid proof

function bbs.proof_verify(ciphersuite, pk, proof, header, ph, disclosed_messages_octets, disclosed_indexes)

    local proof_len_floor = 3*OCTET_POINT_LENGTH + 4*OCTET_SCALAR_LENGTH
    if #proof < proof_len_floor then
        error("proof_octets is too short", 2)
    end
    table.sort(disclosed_indexes) -- make sure indexes are sorted
    header = header or O.empty()
    ph = ph or O.empty()
    disclosed_messages_octets = disclosed_messages_octets or {}
    disclosed_indexes = disclosed_indexes or {}
    local len_U = math.floor((#proof-proof_len_floor)/OCTET_SCALAR_LENGTH)
    local len_R = table_size(disclosed_indexes)
    if disclosed_indexes[1] <= 0 then
        error('Disclosed indexes contains an integer less than or equal to 0', 2)
    end
    if disclosed_indexes[#disclosed_indexes] > len_R+len_U then
        error('Disclosed index contains an integer which exceeds the total  number of messages', 2)
    end
    for i = 2, len_R, 1 do
        if disclosed_indexes[i] == disclosed_indexes[i - 1] then
            error('disclosed indexes contains duplicates', 2)
        end
    end
    local message_scalars = bbs.messages_to_scalars(ciphersuite, disclosed_messages_octets)
    local generators = bbs.create_generators(ciphersuite, len_U+len_R+1)

    return core_proof_verify(ciphersuite, pk, proof, generators, header, ph, message_scalars, disclosed_indexes)

end

return bbs

