credential = [[
    {
        "@context": [
          "https://www.w3.org/2018/credentials/v1",
          "https://www.w3.org/2018/credentials/examples/v1"
        ],
        "id": "http://example.gov/credentials/3732",
        "type": ["VerifiableCredential", "UniversityDegreeCredential"],
        "issuer": "https://example.edu",
        "issuanceDate": "2010-01-01T19:73:24Z",
        "credentialSubject": {
          "id": "did:example:ebfeb1f712ebc6f1c276e12ec21",
          "degree": {
            "type": "BachelorDegree",
            "name": "Bachelor of Science and Arts"
          }
        }
    }
]]

local cred_table = JSON.decode(credential)
local cred_oct = ZEN.serialize(cred_table)

-- generate test keypair
-- TODO: JWK read write from RFC7517
local kp = ECDH.keygen() -- { private, public }
local signature = ECDH.sign(kp.private, cred_oct)

print(#signature.r)
print(#signature.s)
-- render in JWT with header, unencoded (RFC7797)
local header = OCTET.from_string(
        JSON.encode({alg = "ES256K",
                     b64 = true,
                     crit = "b64" }))
local jws = url64(header) .. '..' .. url64(signature.r .. signature.s)
-- insert signature into credential as proof 
cred_table.proof = {
        type = "Signature", -- TODO: check what to write here for secp256k1
        created = "2018-06-18T21:19:10Z",
        proofPurpose = "assertionMethod", -- TODO: check
        verificationMethod = "https://example.com/jdoe/keys/1", -- public key published on APIroom
        jws = jws -- save the encoded JWS here
}
local cred_signed = JSON.encode( cred_table )
I.print(cred_table)
---------------------------------------
-- VERIFY

local v_cred_table = JSON.decode( cred_signed )
local v_proof = cred_table.proof
v_cred_table.proof = nil
v_cred_oct = ZEN.serialize(v_cred_table)
assert(v_cred_oct == cred_oct) -- check serialization is deterministic
local v_jws = strtok(v_proof.jws,'[^.]*')
-- parse header
local v_header = JSON.decode( v_jws[1] )
I.print(v_header)
-- parse signature
local v_sigoct = OCTET.from_url64(v_jws[3])
local v_signature = { }
-- separate r[32] .. s[32] using 'chop'
v_signature.r, v_signature.s = OCTET.chop(v_sigoct,32)
-- verify the signature
assert( ECDH.verify(kp.public, v_cred_oct, v_signature) )
