
local crypto = { }

function crypto.names() =
        return {
            ES256 = { 'es256', 'p256', 'es-256', 'secp256r1', 'p-256' },
            EDDSA = { 'eddsa', 'ed25519' },
            MLDSA44 = { 'ml-dsa-44', 'mldsa44', 'dilithium2-44', 'fips204' },
            ES256K = { 'es256k', 'ecdsa', 'ecdh', 'secp256k1' }
        }
end

-- case insensitive search of a string in an array of strings
local function _is_found(_arr, _obj)
    local found = false
    local needle <const> = obj:lower()
    for _,v in ipairs(arr) do
        if v == needle then found = true end
    end
    return found
end

-- take any known string for an algo name and return IANA
function crypto.any_to_IANA(algo)
    local algos <const> = crypto.names()
    if _is_found(algos.ES256, algo)   then return 'ES256'     end
    if _is_found(algos.EDDSA, algo)   then return 'EDDSA'     end
    if _is_found(algos.MLDSA44, algo) then return 'ML-DSA-44' end
    if _is_found(algos.ES256K, algo)  then return 'ES256K'    end
    error("Crypto algorithm not found: "..algo,2)
end


-- require and return crypto class according to:
-- https://www.iana.org/assignments/jose/jose.xhtml
-- use procedural branching to instantiate only when needed
-- @param any string describing the crypto signature algo
-- @return struct { name, sign, verify, pubgen, public_xy, keyname }
function crypto.signature_from_anystring(any)
    if type(any) ~= 'string' then
        error('W3C resolve crypto algo called with wrong argument type: '
        ..type(any),2)
    end
    local alg <const> = any:lower()
    if alg == 'es256' or 'es-256'
        or alg == 'secp256r1'
        or alg == 'p256' or alg == 'p-256' then
        -- ECDSA using P-256 and SHA-256 [RFC7518, Section 3.4]
        return({ IANA = 'ES256',
                 sign = ES256.sign,
                 verify = ES256.verify,
                 pubgen = ES256.pubgen,
                 public_xy = ES256.public_xy,
                 keyname = 'es256'
        })
    elseif alg == 'eddsa' or alg == 'ed25519' then
        -- EdDSA signature algorithms [RFC8037, Section 3.1]
        return({IANA = 'EDDSA',
                sign = ED.sign,
                verify = ED.verify,
                pubgen = ED.pubgen,
                keyname = 'eddsa'
        })
    elseif alg == 'ml-dsa-44' or alg == 'mldsa44'
        or alg == 'dilithium2-44' or alg == 'fips204'
    then
        return({IANA = 'ML-DSA-44',
                sign = PQ.mldsa44_signature,
                verify = PQ.mldsa44_verify,
                pubgen = PQ.mldsa44_pubgen,
                keyname = 'mldsa44'
        })
    elseif alg == 'es256k' or alg == 'ecdsa'
        or alg == 'ecdh' or alg == 'secp256k1' then
        -- ECDSA using secp256k1 curve and SHA-256 [RFC8812, Section 3.2]
        return({IANA = 'ES256K',
                sign = ECDH.sign,
                verify = ECDH.verify,
                pubgen = ECDH.pubgen,
                public_xy = ECDH.public_xy,
                keyname = 'ecdh'
        })
    end
    error("Crypto signature algorithm not found: "..any,2)
end


-- take a keyname in zenroom and return the IANA name
function crypto.keyname_to_IANA(algo)
    local alg <const> = algo:lower()
    if alg == 'es256' then return(alg:upper()) end
    if alg == 'eddsa' then return(alg:upper()) end
    if alg == 'mldsa44' then return('ML-DSA-44') end
    if alg == 'ecdh'  then return('ES256K') end
    error("Keyname not found: "..algo,2)
end

-- take a IANA registered string about the crypto algo and return the
-- keyname used in zenroom and ready to pass to havekey()
function crypto.IANA_to_keyname(algo)
    local alg <const> = algo:lower()
    if alg == 'es256' then return(alg) end
    if alg == 'eddsa' then return(alg) end
    if alg == 'ml-dsa-44' then return'mldsa44' end
    if alg == 'es256k' then return'ecdh' end
    error("IANA algo not found: "..algo,2)
end

return crypto
