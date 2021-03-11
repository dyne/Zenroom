-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2020-2021 Dyne.org foundation
-- designed and written by Denis Roio
-- with help by Alberto Ibrisevich and Andrea D'Intino
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public
-- License along with this program.  If not, see
-- <https://www.gnu.org/licenses/>.

ABC = require_once('crypto_credential')

G2 = ECP2.generator()

local function import_multidarkroom_session_fingerprints_f(o)
    if not o then
        return {}
    end
    local rawarr = deepmap(CONF.input.encoding.fun, o)
    local arr = {}
    for _, v in ipairs(rawarr) do
        table.insert(arr, ECP.new(v))
    end
    return arr
end

ZEN.add_schema(
    {
        bls_public_key = function(obj)
            return ECP2.new(CONF.input.encoding.fun(obj))
        end,
        multidarkroom_session = function(obj)
            return {
                UID = ZEN.get(obj, 'UID', ECP.new),
                SM = ZEN.get(obj, 'SM', ECP.new),
                verifier = ZEN.get(obj, 'verifier', ECP2.new),
                fingerprints = import_multidarkroom_session_fingerprints_f(
                    obj.fingerprints
                )
            }
        end,
        multidarkroom_signature = function(obj)
            return {
                UID = ZEN.get(obj, 'UID', ECP.new),
                signature = ZEN.get(obj, 'signature', ECP.new),
                proof = import_credential_proof_f(obj.proof),
                zeta = ZEN.get(obj, 'zeta', ECP.new)
            }
        end
    }
)

When(
    'create the bls key',
    function()
        -- keygen: δ = r.O ; γ = δ.G2
        initkeys 'bls'
        ACK.keys.bls = INT.random() -- BLS secret signing key
    end
)

When(
    'create the bls public key',
    function()
        empty 'bls public key'
        havekey 'bls'
        ACK.bls_public_key = G2 * ACK.keys.bls
    end
)

When(
    "aggregate the bls public key from array ''",
    function(arr)
        empty 'bls public key'
        local s = have(arr)
        for k, v in pairs(s) do
            if not ACK.bls_public_key then
                ACK.bls_public_key = v
            else
                ACK.bls_public_key = ACK.bls_public_key + v
            end
        end
    end
)

When(
    "create the multidarkroom hash of ''",
    function(doc)
        empty 'multidarkroom hash'
        have(doc)
        if luatype(doc) == 'table' then
            ACK.multidarkroom_hash = ZEN.serialize(ECP.hashtopoint(doc))
        else
            ACK.multidarkroom_hash = ECP.hashtopoint(doc)
        end
    end
)

When(
    "create the multidarkroom session with UID ''",
    function(uid)
        empty 'multidarkroom session'
        have(uid)
        have 'multidarkroom public key'
        -- init random and uid
        local UID = ECP.hashtopoint(uid)
        local r = INT.random()
        ACK.multidarkroom_session = {
            UID = UID,
            SM = UID * r,
            verifier = ACK.multidarkroom_public_key + G2 * r
        }
    end
)

When(
    'create the multidarkroom signature',
    function()
        empty 'multidarkroom signature'
        have 'multidarkroom session'
        have 'issuer public key'
        -- aggregate all credentials
        local pubcred = false
        for k, v in pairs(ACK.issuer_public_key) do
            if not pubcred then
                pubcred = v
            else
                pubcred = {
                    pubcred.alpha + v.alpha,
                    pubcred.beta + v.beta
                }
            end
        end
        local p, z =
            ABC.prove_cred_uid(
            pubcred,
            ACK.credentials,
            ACK.keys.credential,
            ACK.multidarkroom_session.UID
        )
        ACK.multidarkroom_signature = {
            UID = ACK.multidarkroom_session.UID,
            signature = ACK.multidarkroom_session.UID * ACK.keys.bls,
            proof = p,
            zeta = z
        }
    end
)

When(
    'prepare credentials for verification',
    function()
        have 'credential'
        local res = false
        for k, v in pairs(ACK.issuer_public_key) do
            if not res then
                res = {alpha = v.alpha, beta = v.beta}
            else
                res.alpha = res.alpha + v.alpha
                res.beta = res.beta + v.beta
            end
        end
        ACK.verifiers = res
    end
)

When(
    'verify the multidarkroom signature credential',
    function()
        have 'multidarkroom_signature'
        have 'verifiers'
        have 'multidarkroom_session'
        ZEN.assert(
            ABC.verify_cred_uid(
                ACK.verifiers,
                ACK.multidarkroom_signature.proof,
                ACK.multidarkroom_signature.zeta,
                ACK.multidarkroom_session.UID
            ),
            'Signature has an invalid credential to sign'
        )
    end
)

When(
    'check the multidarkroom signature fingerprint is new',
    function()
        have 'multidarkroom_signature'
        have 'multidarkroom_session'
        if not ACK.multidarkroom_session.fingerprints then
            return
        end
        ZEN.assert(
            not ACK.multidarkroom_session.fingerprints[
                ACK.multidarkroom_signature.zeta
            ],
            'Signature fingerprint is not new'
        )
    end
)

When(
    'add the multidarkroom fingerprint to the multidarkroom session',
    function()
        have 'multidarkroom_signature'
        have 'multidarkroom_session'
        if not ACK.multidarkroom_session.fingerprints then
            ACK.multidarkroom_session.fingerprints = {
                ACK.multidarkroom_signature.zeta
            }
        else
            table.insert(
                ACK.multidarkroom_session.fingerprints,
                ACK.multidarkroom_signature.zeta
            )
        end
    end
)

When(
    'add the multidarkroom signature to the multidarkroom session',
    function()
        have 'multidarkroom_session'
        have 'multidarkroom_signature'
        ACK.multidarkroom_session.SM =
            ACK.multidarkroom_session.SM +
            ACK.multidarkroom_signature.signature
    end
)

When(
    'verify the multidarkroom session is valid',
    function()
        have 'multidarkroom_session'
        ZEN.assert(
            ECP2.miller(
                ACK.multidarkroom_session.verifier,
                ACK.multidarkroom_session.UID
            ) == ECP2.miller(G2, ACK.multidarkroom_session.SM),
            "multidarkroom session doesn't validates"
        )
    end
)
