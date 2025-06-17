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

local LF = require_once'crypto_longfellow'

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
    if not circ.attributes then
        error("longfellow circuit is missing number of attributes",2)
    end
    if not circ.zkspec then
        error("longfellow circuit is missing zkspec version",2)
    end
    return({
            compressed = schema_get(compressed,'.'),
            system =     O.from_string(system),
            version =    BIG.from_decimal(version),
            attributes = BIG.from_decimal(num_attributes),
            zkspec =     BIG.from_decimal(num)
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
    if not circ.attributes then
        error("longfellow circuit is missing number of attributes",2)
    end
    if not circ.zkspec then
        error("longfellow circuit is missing zkspec version",2)
    end
    local conv <const> = CONF.output.encoding.fun
    return({
            compressed = conv(compressed),
            system =     O.to_string(system),
            version =    tonumber(BIG.to_decimal(version)),
            attributes = tonumber(BIG.to_decimal(num_attributes)),
            zkspec =     tonumber(BIG.to_decimal(num))
           })
end

ZEN:add_schema(
    {
        longfellow_circuit = {
            import = import_longfellow_circuit_f,
            expirt = export_longfellow_circuit_f
        },
        longfellow_proof = {
            import = import_longfellow_proof_f,
            export = export_longfellow_proof_f
        }
    }
)

When("create longfellow circuit id ''", function(circuit_id)
         empty'longfellow circuit'
         local id <const> = tonumber(circuit_id)
         ACK.longfellow_circuit = LF.generate_circuit(id)
         new_codec'longfellow circuit'
end)

When("create longfellow proof of attributes '' in mdoc ''",
     function(attributes, mdoc)
         empty'longfellow proof'
         local circ <const> = have'longfellow circuit'
         local trans <const> = have'longfellow transcript'
         local pk <const> = have'public key'
         local attr <const> = have(attributes)
         zencode_assert(isdictionary(attr),
                        "attributes are not a dictionary")
         local mdoc <const> = have(mdoc)
         local pkx <const> = pk:sub(1,32)
         local pky <const> = pk:sub(33,64)
         local now <const> =
             O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ",
                                   os.time(os.date("!*t"))))
         ACK.longfellow_proof = LF.mdoc_prover
         (circuit, mdoc, pkx, pky, trans,
          deepmap(O.to_string, attr), now)
         -- TODO: convert all proof contents to octets?
         new_codec'longfellow proof'
end)
