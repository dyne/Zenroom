--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Matteo Cristino
--on Friday, 20th June 2025
--]]

local jose = { }

-- create a jwk encoded key starting from the sk/pk
-- @param alg alg in jwk
-- @param sk_flag sk flag, if true the alg sk will be inserted in the jwk
-- @param pk a specific public key to be used
-- @return jwk
function jose.create_jwk(alg, sk_flag, pk)
    if sk_flag and pk then
        error('JWK can not be created with zenroom sk and custom pk', 2)
    end
    local crypto <const> = CRYPTO.load(alg)
    local jwk = { alg = O.from_string(crypto.IANA) }
    local sk
    if sk_flag then
        sk = havekey(crypto.keyname)
    end
    local pub = pk or mayhave'es256 public key'
    if not pub and crypto.pubgen then
        if not sk then
            sk = havekey(crypto.keyname)
        end
        pub = crypto.pubgen(sk)
    end
    if crypto.IANA == 'ES256' then
        local key_ops = { }
        jwk.kty = O.from_string'EC'
        jwk.crv = O.from_string'P-256'
        if pub then
            table.insert(key_ops,O.from_string'verify')
            -- custom call since we know has .public_xy
            jwk.x, jwk.y = crypto.class.public_xy(pub)
        end
        if sk_flag then
            table.insert(key_ops,O.from_string'sign')
            jwk.d = sk
        end
        jwk.key_ops = key_ops
        return jwk
    end
    if crypto.IANA == 'EDDSA' then
        local key_ops = { }
        jwk.kty = O.from_string'EC'
        jwk.crv = O.from_string'P-256'
        if pub then
            table.insert(key_ops,O.from_string'verify')
            jwk.x = pub
        end
        if sk_flag then
            table.insert(key_ops,O.from_string'sign')
            jwk.d = sk
        end
        jwk.key_ops = key_ops
        return jwk
    end
    if crypto.IANA == 'ES256K' then
        local key_ops = { }
        jwk.kty = O.from_string'EC'
        jwk.crv = O.from_string'secp256k1'
        if pub then
            table.insert(key_ops,O.from_string'verify')
            -- custom call since we know has .public_xy
            jwk.x, jwk.y = crypto.class.public_xy(pub)
        end
        if sk_flag then
            table.insert(key_ops,O.from_string'sign')
            jwk.d = sk
        end
        jwk.key_ops = key_ops
        return jwk
    end
    if crypto.IANA == 'ML-DSA-44' then
        local key_ops = { }
        if pub then
            table.insert(key_ops,O.from_string'verify')
            jwk.x = pub
        end
        if sk_flag then
            table.insert(key_ops,O.from_string'sign')
            jwk.d = sk
        end
        jwk.alg = O.from_string(crypto.IANA)
        jwk.kty = O.from_string'AKP'
        jwk.param = O.from_string'44'
        jwk.key_ops = key_ops
        return jwk
    end
    error('Unsupported JWK crypto algorithm: '..alg,2)
end

-- generate a JWS signature
-- @param s the signature, if not present payload can not be empty string
-- @param h the header (optional), default is ecdsa on secp256k1
-- @param p the payload (optional), default is empty string
-- @param d the detached flag, if set to true and payload is present, remove payload from jws
-- @return octet string containing the jws
function jose.create_jws(s, h, p, d)
    if h and luatype(h) ~= 'table' then
        error('JOSE create JWS wrong argument type for header: '
              ..type(h),2)
    end
    local function _headers_from_octets(ho)
        local t <const> = type(ho)
        if iszen(t) then
            return ho:octet():to_string()
        end
        if t == 'boolean' then return ho end
        return tostring(t)
    end
    local header = { -- default
        alg = 'ES256K',
        b64 = true,
        crit = {'b64'}
    }
    if h then header = deepmap(_headers_from_octets,h) end
    local dot <const> = O.from_string('.')
    local payload = p -- may be changed by detached flag
    local signature = s
    if not signature then
        if not payload then
            error('Can not create a jws signature without the payload', 2)
        end
        if not header.alg then
            error('Algorithm not specified in jws header', 2)
        end
        local to_be_signed <const> =
            JSON.serialize(header)
            ..
            O.from_string('.')
            ..
            JSON.serialize(payload)
        local crypto <const> = CRYPTO.load(header.alg)
        local sk <const> = havekey(crypto.keyname)
        signature = crypto.sign(sk, to_be_signed)
    end
    payload = (d and O.from_string('')) or payload
    if luatype(signature) == 'table' then
        if not(signature.r and signature.s) then
            error('The signature table does not contains r and s', 2)
        end
        signature = signature.r:pad(32) .. signature.s:pad(32)
    end
    return (JSON.serialize(header)
            ..dot..
            JSON.serialize(payload)
            ..dot..
            JSON.serialize(signature))
end

-- Parse a JWS string and return a structure with header, payload and
-- signature in a dictionary:
-- { header, header_enc, payload, payload_enc, signature, signature_enc }
function jose.parse_jws(jws_enc)
    local tjws    <const> = strtok(O.to_string(jws_enc), '.')
    if tjws[1] == '' then error("The JWS has no header", 2) end
    if not JSON.validate(O.from_url64(tjws[1]):string()) then
        error("The JWS header is not a valid JSON",2) end
    if tjws[3] == '' then error("The JWS has no signature", 2) end
    local ho <const> = O.from_string(tjws[1])
    local res = {
        header_enc = ho,
        header = JSON.deserialize(ho)
    }
    if luatype(res.header) ~= 'table' then
        error('The JWS header is not a dictionary', 2) end
    if tjws[2] ~= '' then
        local po <const> = O.from_string(tjws[2])
        res.payload_enc = po
        res.payload = JSON.deserialize(po)
    end
    local so <const> = O.from_string(tjws[3])
    res.signature_enc = so
    res.signature = JSON.deserialize(so)
    return res
end

-- Extract the public key from a JWK inside the a JWS header: it may
-- contain the pk of the signature when typ is dpop+jwt and header.jwk
-- is present among other requirements defined in:
-- oauth-dpop's 4.2. DPoP Proof JWT Syntax
-- https://www.ietf.org/archive/id/draft-ietf-oauth-dpop-13.html
-- @param header the jws header that should contain the public key
-- @param crypto crypto algo that is already resolved for this header
-- @return pk and crypto algo
function jose.jwk_to_pk(header, crypto)
    if header.typ ~= 'dpop+jwt' then
        warn("JWS type is not 'dpop+jwt': "..(header.typ or 'nil'))
        -- return nil
    end
    if not header.jwk then
        warn("JWS header doesn't contains a jwk")
        return nil
    end
    if header.jwk.kty ~= 'EC' then
        warn('JWK public key type is not EC', 2)
        return nil
    end
    if not header.jwk.crv then
        warn('JWK curve type undefined', 2)
        return nil
    end
    local jwk_crypto <const> =
        CRYPTO.load(header.jwk.crv)
    if crypto and jwk_crypto.keyname ~= crypto.keyname then
        warn('JWK crypto algo is different from JWS: '..jwk_crypto.keyname)
        return nil
    end
    local res
    if header.jwk.x and header.jwk.y then
        res = O.from_url64(header.jwk.x):pad(32)
            ..O.from_url64(header.jwk.y):pad(32)
    else
        warn("JWK misses public key coordinates x/y", 2)
        return nil
    end
    return res, jwk_crypto
end

return jose
