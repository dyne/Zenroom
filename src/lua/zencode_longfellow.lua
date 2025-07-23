--[[
--This file is part of zenroom
--
--Copyright (C) 2025 Dyne.org foundation
--designed, written and maintained by Denis Roio
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

local LF <const> = require_once'crypto_longfellow'
local P256 <const> = require_once'es256'
local OUTCONV <const> = CONF.output.encoding.fun

local function import_longfellow_circuit_f(circ)
    if not isdictionary(circ) then
        error("longfellow circuit is not a dictionary (missing metadata)",2)
    end
    if not circ.compressed then
        error("longfellow circuit is missing compressed data",2)
    end
    if not circ.system then
        error("longfellow circuit is missing system name",2)
    end
    if not circ.version then
        error("longfellow circuit is missing version number",2)
    end
    if not circ.num_attributes then
        error("longfellow circuit is missing number of attributes",2)
    end
    if not circ.zkspec then
        error("longfellow circuit is missing zkspec version",2)
    end
    return({
            compressed = schema_get(circ.compressed,'.'),
            system =     O.from_string(circ.system),
            version =    BIG.from_decimal(circ.version),
            num_attributes = BIG.from_decimal(circ.num_attributes),
            zkspec =     BIG.from_decimal(circ.zkspec),
            hash       = O.from_hex(circ.hash)
           })
end

local function export_longfellow_circuit_f(circ)
    if not isdictionary(circ) then
        error("longfellow circuit is not a dictionary (missing metadata)",2)
    end
    if not circ.compressed then
        error("longfellow circuit is missing compressed data",2)
    end
    if not circ.system then
        error("longfellow circuit is missing system name",2)
    end
    if not circ.version then
        error("longfellow circuit is missing version number",2)
    end
    if not circ.num_attributes then
        error("longfellow circuit is missing number of attributes",2)
    end
    if not circ.zkspec then
        error("longfellow circuit is missing zkspec version",2)
    end
    local conv <const> = CONF.output.encoding.fun
    return({
            compressed = conv(circ.compressed),
            system =     O.to_string(circ.system),
            version =    tonumber(BIG.to_decimal(circ.version)),
            num_attributes = tonumber(BIG.to_decimal(circ.num_attributes)),
            zkspec =     tonumber(BIG.to_decimal(circ.zkspec)),
            hash =       O.to_hex(sha256(circ.compressed))
           })
end

local function import_longfellow_attributes_f(val)
    local res = { }
    for _,v in ipairs(val) do
        local imp = { id = O.from_string(v.id) }
              imp.value  = O.from_string(v.value)
        table.insert(res, imp)
    end
    return res
end

local function import_longfellow_proof_f(val)
    return({ zk = schema_get(val, 'zk'),
             zkspec = schema_get(val, 'zkspec', INT.new) })
end
local function export_longfellow_proof_f(val)
    return({ zk = OUTCONV(val.zk),
             zkspec = tonumber(BIG.to_decimal(val.zkspec)) })
end

ZEN:add_schema(
    {
        attributes = {
            import = import_longfellow_attributes_f,
            export = export_longfellow_attributes_f,
        },
        circuit = {
            import = import_longfellow_circuit_f,
            export = export_longfellow_circuit_f
        },
        proof = {
            import = import_longfellow_proof_f,
            export = export_longfellow_proof_f
        }
    }
)

When("create circuit id ''", function(circuit_id)
         empty'longfellow circuit'
         local id <const> = tonumber(circuit_id)
         ACK.circuit = LF.generate_circuit(id)
         new_codec'circuit'
end)

When("create proof of attributes '' in mdoc ''",
     function(attributes, mdoc)
         empty'longfellow proof'
         local circ <const> = have'circuit'
         local trans <const> = have'transcript'
         local now <const> = mayhave'now' or
             O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ",
                                   os.time(os.date("!*t"))))
         local pk <const> = have'public key'
         zencode_assert(#pk==64, "public key length is not 64 bytes (P256)")
         zencode_assert(P256.pubcheck(pk), "invalid P256 public key")
         local attr <const> = have(attributes)
         local document <const> = have(mdoc)
         local pkx <const> = pk:sub(1,32)
         local pky <const> = pk:sub(33,64)
         ACK.proof = LF.mdoc_prover
         (circ, document, pkx, pky, trans,
          deepmap(O.to_string, attr), now)
         zencode_assert(ACK.proof,"Longfellow proof generation error")
         -- TODO: convert all proof contents to octets?
         new_codec'proof'
end)


When("verify proof of attributes '' in proof ''",
     function(attributes, proof)
         local circ <const> = have'circuit'
         local trans <const> = have'transcript'
         local now <const> = mayhave'now' or
             O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ",
                                   os.time(os.date("!*t"))))
         local pk <const> = have'public key'
         zencode_assert(#pk==64, "public key length is not 64 bytes (P256)")
         zencode_assert(P256.pubcheck(pk), "invalid P256 public key")
         local attr <const> = have(attributes)
         local zk <const> = have(proof)
         local pkx <const> = pk:sub(1,32)
         local pky <const> = pk:sub(33,64)
         zencode_assert( LF.mdoc_verifier
                         (circ, zk, pkx, pky, trans,
                          deepmap(O.to_string, attr), now,
                          O.from_string('org.iso.18013.5.1.mDL')),
                         "Error in longfellow ZK verification: invalid proof")
         -- TODO: convert all proof contents to octets?
end)
