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
longfellow['true'] = O.from_hex'f5'

longfellow['false'] = O.from_hex'f4'

longfellow.mdoc_example = function(num)
    local res <const> = c_zk.mdoc_example(num)
    if not res then
        error("Longfellow-ZK MDOC example not found: "..num,2)
    end
    return res
end

longfellow.generate_circuit = function(num)
    local res <const> = { compressed = c_zk.gen_circuit(num),
                          zkspec = num }
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
    end
    if not type(circuit.compressed)=='zenroom.octet' then
        error("Invalid compressed circuit not an octet",2)
    end
    if not type(mdoc)=='zenroom.octet' or mdoc < 64 then
        error("Invalid MDOC either too small or not an octet",2)
    end
    if #pkx ~= 32 or #pky ~= 32
        or type(pkx) ~= 'zenroom.octet'
        or type(pky) ~= 'zenroom.octet' then
        error("Invalid public keys coordinates x or y",2)
    end
    if type(trans)~='zenroom.octet' or #trans < 32 then
        error("Invalid transcript not an octet",2)
    end
    if type(attr)~='table' or #attr < 1
        or not attr[1].id or not attr[1].value then
        error("Invalid attributes table",2)
    end
    -- get UTC time (ZULU) using '!*t' to avoid timezone conversion
    -- then format as "YYYY-MM-DDTHH:MM:SSZ" (20 chars)
    local nownow <const> = now
        or O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ",
                                 os.time(os.date("!*t")))
    local proof <const> =
        c_zk.mdoc_prove(circuit.compressed,
                        mdoc, pkx, pky, trans,
                        attr, nownow, circuit.zkspec)
    if not proof then
        error("Proof creation error",2)
    end
    return proof
end

longfellow.circuit_id = function(circ)
    local res <const> = c_zk.circuit_id(circ.compressed, circ.zkspec)
    if not res then
        error("Unrecognized ZK circuit ID",2)
    end
    return O.from_string(res:hex())
end

return longfellow
