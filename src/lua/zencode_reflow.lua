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

local function import_reflow_session_fingerprints_f(o)
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
        reflow_session = function(obj)
            return {
                UID = ZEN.get(obj, 'UID', ECP.new),
                SM = ZEN.get(obj, 'SM', ECP.new),
                verifier = ZEN.get(obj, 'verifier', ECP2.new),
                fingerprints = import_reflow_session_fingerprints_f(
                    obj.fingerprints
                )
            }
        end,
        reflow_signature = function(obj)
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
    "create the reflow hash of ''",
    function(doc)
        empty 'reflow hash'
        have(doc)
        if luatype(doc) == 'table' then
            ACK.reflow_hash = ZEN.serialize(ECP.hashtopoint(doc))
        else
            ACK.reflow_hash = ECP.hashtopoint(doc)
        end
    end
)

When(
    "create the reflow session with UID ''",
    function(uid)
        empty 'reflow session'
        have(uid)
        have 'reflow public key'
        -- init random and uid
        local UID = ECP.hashtopoint(uid)
        local r = INT.random()
        ACK.reflow_session = {
            UID = UID,
            SM = UID * r,
            verifier = ACK.reflow_public_key + G2 * r
        }
    end
)

When(
    'create the reflow signature',
    function()
        empty 'reflow signature'
        have 'reflow session'
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
            ACK.reflow_session.UID
        )
        ACK.reflow_signature = {
            UID = ACK.reflow_session.UID,
            signature = ACK.reflow_session.UID * ACK.keys.bls,
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
    'verify the reflow signature credential',
    function()
        have 'reflow_signature'
        have 'verifiers'
        have 'reflow_session'
        ZEN.assert(
            ABC.verify_cred_uid(
                ACK.verifiers,
                ACK.reflow_signature.proof,
                ACK.reflow_signature.zeta,
                ACK.reflow_session.UID
            ),
            'Signature has an invalid credential to sign'
        )
    end
)

When(
    'check the reflow signature fingerprint is new',
    function()
        have 'reflow_signature'
        have 'reflow_session'
        if not ACK.reflow_session.fingerprints then
            return
        end
        ZEN.assert(
            not ACK.reflow_session.fingerprints[
                ACK.reflow_signature.zeta
            ],
            'Signature fingerprint is not new'
        )
    end
)

When(
    'add the reflow fingerprint to the reflow session',
    function()
        have 'reflow_signature'
        have 'reflow_session'
        if not ACK.reflow_session.fingerprints then
            ACK.reflow_session.fingerprints = {
                ACK.reflow_signature.zeta
            }
        else
            table.insert(
                ACK.reflow_session.fingerprints,
                ACK.reflow_signature.zeta
            )
        end
    end
)

When(
    'add the reflow signature to the reflow session',
    function()
        have 'reflow_session'
        have 'reflow_signature'
        ACK.reflow_session.SM =
            ACK.reflow_session.SM +
            ACK.reflow_signature.signature
    end
)

When(
    'verify the reflow session is valid',
    function()
        have 'reflow_session'
        ZEN.assert(
            ECP2.miller(
                ACK.reflow_session.verifier,
                ACK.reflow_session.UID
            ) == ECP2.miller(G2, ACK.reflow_session.SM),
            "reflow session doesn't validates"
        )
    end
)
