--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
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
--Last modified by Denis Roio
--on Wednesday, 14th July 2021
--]]


ZEN.add_schema(
    {
        -- flexible verifiable credential
        -- only internal 'jws' member has peculiar encoding
        verifiable_credential = function(obj)
            ZEN.CODEC.verifiable_credential = {
                name = 'verifiable_credential',
                encoding = 'string',
                zentype = 'schema',
                luatype = 'table'
            }
            return (deepmap(OCTET.from_string, obj))
        end
    }
)

-- return { r , s } table suitable for signature verification
local function jws_octet_to_signature(obj)
    local toks = strtok(OCTET.to_string(obj), '[^.]*')
    -- header parsing may be skipped
    -- local header = JSON.decode( OCTET.from_url64(toks[1]):to_string() )
    local res = {}
    res.r, res.s = OCTET.chop(OCTET.from_url64(toks[3]), 32)
    return (res)
end

-- return octet string suitable for JWS encapsulation
local function jws_signature_to_octet(obj)
    local header =
        OCTET.from_string(
        JSON.encode(
            {
                alg = 'ES256K',
                b64 = true,
                crit = 'b64'
            }
        )
    )
    return (OCTET.to_url64(header) ..
        '..' .. OCTET.to_url64(obj.r .. obj.s))
end

When(
    "set the verification method in '' to ''",
    function(vc, meth)
        local cred = have(vc)
        ZEN.assert(cred.proof, 'The object is not signed: ' .. vc)
        local m = have(meth)
        ACK[vc].proof.verificationMethod = m
    end
)

When(
    "get the verification method in ''",
    function(vc)
        empty 'verification_method'
        local cred = have(vc)
        ZEN.assert(cred.proof, 'The object is not signed: ' .. vc)
        ACK.verification_method = cred.proof.verificationMethod
    end
)

When(
    "sign the verifiable credential named ''",
    function(vc)
        local cred = have(vc)
        local keypair = have 'keypair'
        ZEN.assert(
            not cred.proof,
            'The object is already signed: ' .. vc
        )
        local proof = {
            type = 'Zenroom', -- .. VERSION, -- , "Signature", -- TODO: check what to write here for secp256k1
            -- created = "2018-06-18T21:19:10Z",
            proofPurpose = 'authenticate' -- assertionMethod", -- TODO: check
        }
        local cred_str = JSON.encode(cred)
        proof.jws =
            jws_signature_to_octet(
            ECDH.sign(keypair.private_key, OCTET.from_string(cred_str))
        )
        ACK[vc].proof = deepmap(OCTET.from_string, proof)
    end
)

IfWhen(
    "verify the verifiable credential named ''",
    function(vc)
        local cred = have(vc)
        local public_key = have 'public_key'
        ZEN.assert(cred.proof, 'The object has no signature: ' .. vc)
        ZEN.assert(
            cred.proof.jws,
            'The object has no signature: ' .. vc
        )
        local sign = jws_octet_to_signature(cred.proof.jws)
        -- omit the proof subtable from verification
        local proof = cred.proof
        cred.proof = nil
        local cred_str = JSON.encode(cred)
        -- restore proof in HEAP (cred is still a pointer here)
        cred.proof = proof
        -- if public_key is a table then use the first value: support 'from'
        -- extraction, but not multiple keys
        local pub
        if luatype(public_key) == 'table' then
            _, pub = next(public_key)
        else
            pub = public_key
        end
        ZEN.assert(
            ECDH.verify(pub, OCTET.from_string(cred_str), sign),
            'The signature does not validate: ' .. vc
        )
    end
)
