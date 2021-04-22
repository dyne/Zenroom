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

local function import_reflow_seal_fingerprints_f(o)
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
        reflow_seal = function(obj)
            return {
                identity = ZEN.get(obj, 'identity', ECP.new),
                SM = ZEN.get(obj, 'SM', ECP.new),
                verifier = ZEN.get(obj, 'verifier', ECP2.new),
                fingerprints = import_reflow_seal_fingerprints_f(
                    obj.fingerprints
                )
            }
        end,
        reflow_signature = function(obj)
            return {
                identity = ZEN.get(obj, 'identity', ECP.new),
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
        for _, v in pairs(s) do
            if not ACK.bls_public_key then
                ACK.bls_public_key = v
            else
                ACK.bls_public_key = ACK.bls_public_key + v
            end
        end
    end
)

When(
    "create the reflow identity of ''",
    function(doc)
        empty 'reflow identity'
        local src = have(doc)
        if luatype(src) == 'table' then
            ACK.reflow_identity = ECP.hashtopoint(ZEN.serialize(src))
        else
            ACK.reflow_identity = ECP.hashtopoint(src)
        end
    end
)

local function _create_reflow_seal_f(uid)
    empty 'reflow seal'
    have(uid)
    have 'reflow public key'
    local UID = ACK[uid]
    ZEN.assert(type(UID) == 'zenroom.ecp',
                            "Invalid reflow identity: "
                            ..uid.." ("..type(UID)..")")
    local r = INT.random()
    ACK.reflow_seal = {
        identity = UID,
        SM = UID * r,
        verifier = ACK.reflow_public_key + G2 * r
    }
end

When(
    "create the reflow seal with identity ''",
    _create_reflow_seal_f)
When("create the reflow seal",
    function() _create_reflow_seal_f('reflow identity') end)

When(
    'create the reflow signature',
    function()
        empty 'reflow signature'
        have 'reflow seal'
        have 'issuer public key'
        -- aggregate all credentials
        local pubcred = false
        for _, v in pairs(ACK.issuer_public_key) do
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
            ACK.reflow_seal.identity
        )
        ACK.reflow_signature = {
            identity = ACK.reflow_seal.identity,
            signature = ACK.reflow_seal.identity * ACK.keys.bls,
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
        for _, v in pairs(ACK.issuer_public_key) do
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
        have 'reflow_seal'
        ZEN.assert(
            ABC.verify_cred_uid(
                ACK.verifiers,
                ACK.reflow_signature.proof,
                ACK.reflow_signature.zeta,
                ACK.reflow_seal.identity
            ),
            'Signature has an invalid credential to sign'
        )
    end
)

When(
    'check the reflow signature fingerprint is new',
    function()
        have 'reflow_signature'
        have 'reflow_seal'
        if not ACK.reflow_seal.fingerprints then
            return
        end
        ZEN.assert(
            not ACK.reflow_seal.fingerprints[ACK.reflow_signature.zeta],
            'Signature fingerprint is not new'
        )
    end
)

When(
    'add the reflow fingerprint to the reflow seal',
    function()
        have 'reflow_signature'
        have 'reflow_seal'
        if not ACK.reflow_seal.fingerprints then
            ACK.reflow_seal.fingerprints = {
                ACK.reflow_signature.zeta
            }
        else
            table.insert(
                ACK.reflow_seal.fingerprints,
                ACK.reflow_signature.zeta
            )
        end
    end
)

When(
    'add the reflow signature to the reflow seal',
    function()
        have 'reflow_seal'
        have 'reflow_signature'
        ACK.reflow_seal.SM =
            ACK.reflow_seal.SM + ACK.reflow_signature.signature
    end
)

When(
    'verify the reflow seal is valid',
    function()
        have 'reflow_seal'
        ZEN.assert(
            ECP2.miller(ACK.reflow_seal.verifier, ACK.reflow_seal.identity)
            ==
            ECP2.miller(G2, ACK.reflow_seal.SM),
            "reflow seal doesn't validates"
        )
    end
)

When(
    "aggregate the reflow seal array in ''",
    function(arr)
        have(arr)
        empty 'reflow seal'
        local dst = {}
        for _, v in pairs(ACK[arr]) do
            if not dst.UID then
                dst.UID = v.UID
            else
                dst.UID = dst.UID + v.UID
            end
            if not dst.SM then
                dst.SM = v.SM
            else
                dst.SM = dst.SM + v.SM
            end
            if not dst.verifier then
                dst.verifier = v.verifier
            else
                dst.verifier = dst.verifier + v.verifier
            end
        end
        ACK.reflow_seal = dst
    end
)
