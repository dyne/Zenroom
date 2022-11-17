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

-- possiblity to add more verififcationMethod specs
-- like base58, jws, ...
local function import_vm(obj, key)
    if key == 'publicKeyBase64' then
	return O.from_base64(obj)
    elseif key == 'publicKeyBase58' then
	return O.from_base58(obj)
    else
	return O.from_string(obj)
    end
end

local function export_vm(obj, key)
    if key == 'publicKeyBase64' then
	return O.to_base64(obj)
    elseif key == 'publicKeyBase58' then
	return O.to_base58(obj)
    else
	return O.to_string(obj)
    end
end

local function import_did_doc(doc)
    local res = {}
    -- id is always present in DID-documents
    res.id = ZEN.get(doc, 'id', O.from_string, tostring)
    -- @context, alsoKnownAs, verificationMethod,Country, State,
    -- desciption, service and proof can also not be present
    if doc['@context'] then
	res['@context'] = deepmap(O.from_string, doc['@context'])
    end
    if doc.alsoKnownAs then
	res.alsoKnownAs = ZEN.get(doc, 'alsoKnownAs', O.from_string, tostring)
    end
    if doc.verificationMethod then
	res.verificationMethod = deepmap(import_vm, doc.verificationMethod)
    end
    if doc.Country then
       res.Country = ZEN.get(doc, 'Country', O.from_string, tostring)
    end
    if doc.State then
       res.State = ZEN.get(doc, 'State', O.from_string, tostring)
    end
    if doc.description then
       res.description = ZEN.get(doc, 'description', O.from_string, tostring)
    end
    -- services
    if doc.service then
       res.service = deepmap(O.from_string, doc.service)
    end
    -- proof
    if doc.proof then
       res.proof = deepmap(O.from_string, doc.proof)
    end
    return res
end

local function export_did_doc(doc)
    local res = {}
    res.id = doc.id:string()
    if doc['@context'] then
	res['@context'] = deepmap(O.to_string, doc['@context'])
    end
    if doc.alsoKnownAs then
	res.alsoKnownAs = doc.alsoKnownAs:string()
    end
    if doc.verificationMethod then
	res.verificationMethod = deepmap(export_vm, doc.verificationMethod)
    end
    if doc.Country then
	res.Country = doc.Country:string()
    end
    if doc.State then
	res.State = doc.State:string()
    end
    if doc.description then
	res.description = doc.description:string()
    end
    -- serivce
    if doc.service then
	res.service = deepmap(O.to_string, doc.service)
    end
    -- proof
    if doc.proof then
	res.proof = deepmap(O.to_string, doc.proof)
    end
    return res
end

local function import_verification_method(doc)
    local res = {}
    for key, ver_method in pairs(doc) do
	if key == "ethereum_address" then
	    res[key] = ZEN.get(doc[key], '.', O.from_hex, tostring)
	elseif key == "eddsa_public_key" then
	    res[key] = ZEN.get(doc[key], '.', O.from_base58, tostring)
	else
	    res[key] = ZEN.get(doc[key], '.', O.from_base64, tostring)
	end
    end
    return res
end

local function export_verification_method(doc)
    local res = {}
    for key, ver_method in pairs(doc) do
	if key == "ethereum_address" then
	    res[key] = O.to_hex(ver_method)
	elseif key == "eddsa_public_key" then
	    res[key] = O.to_base58(ver_method)
	else
	    res[key] = O.to_base64(ver_method)
	end
    end
    return res
end

ZEN.add_schema(
    {
	did_document = { import = import_did_doc,
			 export = export_did_doc },
	verificationMethod = { import = import_verification_method,
			       export = export_verification_method },
        -- flexible verifiable credential
        -- only internal 'jws' member has peculiar encoding
        verifiable_credential = function(obj)
            ACK.verifiable_credential = {}
            new_codec('verifiable_credential', {
                name = 'verifiable_credential',
                encoding = 'string',
                zentype = 'schema',
                luatype = 'table'
            })
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
local function jws_signature_to_octet(obj, algo)
    local header =
        OCTET.from_string(
        JSON.encode(
            {
                alg = algo or 'ES256K', -- default secp256k1
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
        new_codec('verification_method', {
            schema="verificationMethod",
            name="verification_method",
            encoding="complex",
            zentype="schema"
        })
    end
)


When(
    "create the jws signature of ''", function(src)
        local cred = have(src)
	empty'jws'
        local sk = havekey'ecdh' -- assuming secp256k1
        ZEN.assert(not cred.proof,'The object is already signed: ' .. src)
        local proof = {
            type = 'Zenroom v'..ZENROOM_VERSION.original,
	    -- "Signature", -- TODO: check what to write here for secp256k1
            -- created = "2018-06-18T21:19:10Z",
            proofPurpose = 'authenticate' -- assertionMethod", -- TODO: check
        }
	local to_sign
	if luatype(cred) == 'table' then
	   to_sign = OCTET.from_string( JSON.encode(cred) )
	else
	   to_sign = cred
	end
	ACK.jws = OCTET.from_string(
	   jws_signature_to_octet(ECDH.sign(sk, to_sign)) )
	new_codec('jws', { zentype = 'element',
			   encoding = 'string' }) -- url64 encoding is opaque
    end
)

IfWhen(
    "verify the jws signature of ''",
    function(src)
        local jws = have'jws'
	local signed = have(src)
	if luatype(signed) == 'table' then
	   signed = JSON.encode(signed)
	end
        local pub = have 'ecdh public key'
        local signature = jws_octet_to_signature(jws)
        -- omit the proof subtable from verification
        ZEN.assert(
            ECDH.verify(pub, signed, signature),
            'The signature does not validate: ' .. src
        )
    end
)

When(
    "sign the verifiable credential named ''",
    function(vc)
        local cred = have(vc)
        local sk = havekey'ecdh' -- assuming secp256k1
        ZEN.assert(not cred.proof,'The object is already signed: ' .. vc)
        local proof = {
            type = 'Zenroom v'..ZENROOM_VERSION.original,
	    -- "Signature", -- TODO: check what to write here for secp256k1
            -- created = "2018-06-18T21:19:10Z",
            proofPurpose = 'authenticate' -- assertionMethod", -- TODO: check
        }
	local cred_str
	if luatype(cred) == 'table' then
	   cred_str = JSON.encode(cred)
	else
	   cred_str = cred
	end
        proof.jws =
            jws_signature_to_octet(
	      ECDH.sign(sk, OCTET.from_string(cred_str))
        )
        ACK[vc].proof = deepmap(OCTET.from_string, proof)
    end
)

local function _verification_f(doc)
    local d = have(doc)
    ZEN.assert(d.proof and d.proof.jws, 'The object has no signature: ' .. doc)
    local public_key = have 'ecdh public key'
    local pub
    if luatype(public_key) == 'table' then
	_, pub = next(public_key)
    else
	pub = public_key
    end

    -- omit the proof subtable from verification
    local proof = d.proof
    d.proof = nil
    signed = JSON.encode(d)
    -- restore proof in HEAP (cred is still a pointer here)
    d.proof = proof
    
    local signature = jws_octet_to_signature(d.proof.jws)
    
    ZEN.assert(
	ECDH.verify(pub, signed, signature),
	'The signature does not validate: ' .. doc
    )
end

IfWhen(
    "verify the verifiable credential named ''", _verification_f
)

IfWhen(
    "verify the did document named ''", _verification_f
)

-- operations on the did-document
When(
    "create the serviceEndpoint of ''",
    function(did_doc)
	local doc = have(did_doc)
	ZEN.assert(doc.service, 'service not found')
	ACK.serviceEndpoint = {}
	for _, service in pairs(doc.service) do
	    local name = strtok(O.to_string(service.id), '[^#]*')[2]
	    ACK.serviceEndpoint[name] = service.serviceEndpoint
	end
	new_codec('serviceEndpoint', { encoding = 'string',
				       luatype = 'table',
				       zentype = 'dictionary' })
    end
)

When(
    "create the verificationMethod of ''",
    function(did_doc)
	local doc = have(did_doc)
	ZEN.assert(doc.verificationMethod, 'verificationMethod not found')
	empty 'verificationMethod'
	ACK.verificationMethod = {}

	local alias = { EcdsaSecp256k1VerificationKey_b64 = 'ecdh_public_key',
			Ed25519VerificationKey2018 = 'eddsa_public_key',
			ReflowBLS12381VerificationKey_b64 = 'reflow_public_key',
			SchnorrBLS12381VerificationKey_b64 = 'schnorr_public_key',
			Dilithium2VerificationKey_b64 = 'dilithium_public_key',
			EcdsaSecp256k1RecoveryMethod2020 = 'ethereum_address'}

	for _, ver_method in pairs(doc.verificationMethod) do
	    local z_name = alias[O.to_string(ver_method.type)]
	    if ver_method.publicKeyBase64 then
		ACK.verificationMethod[z_name] = ver_method.publicKeyBase64
	    elseif ver_method.publicKeyBase58 then
		ACK.verificationMethod[z_name] = ver_method.publicKeyBase58
	    elseif ver_method.blockchainAccountId then
		local address = strtok(O.to_string(ver_method.blockchainAccountId), '[^:]*')[3]
		ACK.verificationMethod[z_name] = O.from_hex(address)
	    end
	end
	new_codec('verificationMethod', { zentype = 'schema',
					  encoding = 'complex' })
    end
)
