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

local c_zk = require_once'longfellow'

local longfellow = { }

-- values used as true and false in mdoc
longfellow['yes'] = O.from_hex'f5'

longfellow['no'] = O.from_hex'f4'

longfellow.mdoc_example = function(num)
    local res <const> = c_zk.mdoc_example(num)
    if not res then
        error("Longfellow-ZK MDOC example not found: "..num,2)
    end
    return res
end

longfellow.generate_circuit = function(num)
    -- C func returns the compressed circuit and:
	-- lua_pushstring(L,zk_spec->system);
	-- lua_pushstring(L,zk_spec->version);
	-- lua_pushstring(L,zk_spec->num_attributes);
	-- lua_pushstring(L,zk_spec->circuit_hash);

    compressed, system, version,
        num_attributes, circuit_hash = c_zk.gen_circuit(num)

    local res <const> = { compressed = compressed,
                          system =     O.from_string(system),
                          version =    FLOAT.new(version),
                          attributes = FLOAT.new(num_attributes),
                          hash =       O.from_hex(circuit_hash),
                          zkspec =     BIG.new(num) }
    if not res.compressed then
        error("Longfellow-ZK generate circuit failure",2)
    end
    return res
end

longfellow.mdoc_prover = function(circuit, mdoc,
                                  pkx, pky,
                                  trans, attr, now)
    if not type(circuit)=='table' then
        error("Invalid circuit not a table",2)
    elseif type(circuit.compressed)~='zenroom.octet' then
        error("Invalid compressed circuit not an octet",2)
    elseif not type(mdoc)=='zenroom.octet' or mdoc < 64 then
        error("Invalid MDOC either too small or not an octet",2)
    elseif type(trans)~='zenroom.octet' or #trans < 32 then
        error("Invalid transcript not an octet",2)
    elseif #pkx ~= 32 or #pky ~= 32
        or type(pkx) ~= 'zenroom.octet'
        or type(pky) ~= 'zenroom.octet' then
        error("Invalid public keys coordinates x or y",2)
    elseif type(attr)~='table' or #attr < 1
        or not attr[1].id or not attr[1].value then
        error("Invalid attributes table",2)
    end
    for _,v in ipairs(attr) do
        if not v.id then error("Missing id in attributes table",2) end
        if not v.value then error("Missing value in attributes table",2) end
        if luatype(v.value)=='table' then
            error("Invalid table value in attributes",2)
        end
        if luatype(v.id)=='table' then
            error("Invalid table id in attributes",2)
        end
    end
    -- get UTC time (ZULU) using '!*t' to avoid timezone conversion
    -- then format as "YYYY-MM-DDTHH:MM:SSZ" (20 chars)
    local nownow <const> = now
        or O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ",
                                 os.time(os.date("!*t"))))
    if not is_zulu_date(nownow) then
        error("Timestamp is not in ISO 8601 format",2)
    end
    local proof <const> =
    { zk         = c_zk.mdoc_prove(circuit.compressed,
                           mdoc, pkx, pky, trans,
                           attr, nownow, circuit.zkspec:int()),
      zkspec     = circuit.zkspec }
    if not proof.zk then return nil end
    return proof
end

longfellow.mdoc_verifier = function(circuit, proof,
                                    pkx, pky, trans,
                                    attr, now, doc_type)
    if not type(circuit)=='table' then
        error("Invalid circuit not a table",2)
    elseif type(circuit.compressed)~='zenroom.octet' then
        error("Invalid compressed circuit not an octet",2)
    elseif circuit.zkspec ~= proof.zkspec then
        error("Circuit zkspec version does not match proof",2)
    elseif not type(proof)=='table'
        and type(proof.zk) == 'zenroom.octet' then
        error("Invalid proof does not contain a ZK octet",2)
    elseif type(trans)~='zenroom.octet' or #trans < 32 then
        error("Invalid transcript not an octet",2)
    elseif #pkx ~= 32 or #pky ~= 32
        or type(pkx) ~= 'zenroom.octet'
        or type(pky) ~= 'zenroom.octet' then
        error("Invalid public keys coordinates x or y",2)
    elseif type(attr)~='table' or #attr < 1
        or not attr[1].id or not attr[1].value then
        error("Invalid attributes table",2)
    elseif type(doc_type) ~= 'zenroom.octet' then
        error("Invalid doctype not an octet:"..type(doc_type))
    end
    for _,v in ipairs(attr) do
        if not v.id then error("Missing id in attributes table",2) end
        if not v.value then error("Missing value in attributes table",2) end
        if luatype(v.value)=='table' then
            error("Invalid table value in attributes",2)
        end
        if luatype(v.id)=='table' then
            error("Invalid table id in attributes",2)
        end
    end
    -- get UTC time (ZULU) using '!*t' to avoid timezone conversion
    -- then format as "YYYY-MM-DDTHH:MM:SSZ" (20 chars)
    local nownow <const> = now
        or O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ",
                                 os.time(os.date("!*t"))))
    if not is_zulu_date(nownow) then
        error("Timestamp is not in ISO 8601 format",2)
    end
    return c_zk.mdoc_verify(circuit.compressed,
                            proof.zk,
                            pkx, pky,
                            trans,
                            attr,
                            nownow,
                            doc_type,
                            proof.zkspec:int())
end

longfellow.circuit_id = function(circ)
    local res <const> = c_zk.circuit_id(circ.compressed, circ.zkspec:int())
    if not res then
        error("Unrecognized ZK circuit ID",2)
    end
    return res
end

return longfellow
