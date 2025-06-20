--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2025 Dyne.org foundation
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
--on Sunday, 10th April 2022
--]]

load_scenario('zencode_credential')

ABC = require_once('crypto_credential')

local function _export_big_as_octet_f(obj)
    if type(obj) == 'zenroom.big' then
        return obj:octet():base64()
    end
    return obj
end

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

local function import_reflow_seal_f(obj)
   local f
   if obj.fingerprints then
	  f = import_reflow_seal_fingerprints_f(obj.fingerprints)
   else f = nil end
   return {
	  identity = schema_get(obj, 'identity', ECP.new),
	  SM = schema_get(obj, 'SM', ECP.new),
	  verifier = schema_get(obj, 'verifier', ECP2.new),
	  fingerprints = f
   }
end

ZEN:add_schema(
   {
      reflow_public_key = function(obj)
	 return schema_get(obj, '.', ECP2.new)
      end,

      reflow_seal = import_reflow_seal_f,

      reflow_signature = {
	 import = function(obj)
	    return {
	       identity = schema_get(obj, 'identity', ECP.new),
	       signature = schema_get(obj, 'signature', ECP.new),
	       proof = import_credential_proof_f(obj.proof),
	       zeta = schema_get(obj, 'zeta', ECP.new)
	    }
	 end,
	 export = function(obj)
         obj.proof = export_credential_proof_f(obj.proof)
         return obj
     end,
      },
      reflow_identity = function(obj)
	 return schema_get(obj, '.', ECP.new)
      end,
      material_passport = function(obj)
	 return {
	    seal = import_reflow_seal_f(obj.seal),
	    proof = import_credential_proof_f(obj.proof),
	    zeta = schema_get(obj, 'zeta', ECP.new)
	 }
      end
   }
)

local function _makeuid(src)
   local uid
   if luatype(src) == 'table' then
	  uid = ECP.hashtopoint(zencode_serialize(src))
   else
	  uid = ECP.hashtopoint(src)
   end
   return(uid)
end

When("create reflow key",function()
        -- keygen: δ = r.O ; γ = δ.G2
        initkeyring 'reflow'
        ACK.keyring.reflow = INT.random()
        -- BLS secret signing key
end)

When("create reflow key with secret key ''",function(sec)
    local sk = have(sec)
    initkeyring'reflow'
    ACK.keyring.reflow = INT.new(sk)
end)
When("create reflow key with secret ''",
function(sec)
    local sk = have(sec)
    initkeyring'reflow'
    ACK.keyring.reflow = INT.new(sk)
end)

When("create reflow public key",function()
        empty 'reflow public key'
        havekey 'reflow'
        ACK.reflow_public_key = G2 * ACK.keyring.reflow
	new_codec'reflow public key'
end)

When("aggregate reflow public key from array ''",function(arr)
      empty 'reflow public key'
      local s = have(arr)
      zencode_assert(luatype(s) == 'table' and next(s) ~= nil, "Empty table: "..arr)
      local val
      for k, v in pairs(s) do
	 if k == 'reflow_public_key' then val = v
	    -- tolerate about named arrays
	 elseif v.reflow_public_key then val = v.reflow_public_key
	 else zencode_assert(false, "Reflow public key not found in array: "
			 ..arr.."["..#s.."] at key "..k)
	 end
	 if not ACK.reflow_public_key then
	    ACK.reflow_public_key = val
	 else
	    ACK.reflow_public_key = ACK.reflow_public_key + val
	 end
      end
      new_codec'reflow public key'
end)

When("create reflow identity of ''",function(doc)
	empty 'reflow identity'
	ACK.reflow_identity = _makeuid(have(doc))
	new_codec'reflow identity'
end)

When("create reflow identity of objects in ''",function(doc)
	empty 'reflow identity'
	local arr = have(doc)
	zencode_assert(luatype(arr)=='table', "Object is not an array or dictionary: "..doc)
	local first = { }
	for k,v in pairs(arr) do
	   -- if reflow_id already present then check if ECP and use that
	   if v.reflow_identity then
	      local rid = ECP.new(v.reflow_identity)
	      zencode_assert(not rid:isinfinity(),
			 "Object "..doc.."["..k.."] has an invalid reflow identity")
	      table.insert(first, rid)
	   else
	      table.insert(first, _makeuid(v))
	   end
	end
	local res
	for _,v in pairs(first) do
	   if not res then
	      res = v
	   else
	      res = res + v
	   end
	end
	ACK.reflow_identity = res
	new_codec'reflow identity'
end)

local function _create_reflow_seal_f(uid)
    empty 'reflow seal'
    have(uid)
    have 'reflow public key'
    local UID = ACK[uid]
    zencode_assert(type(UID) == 'zenroom.ecp',
                            "Invalid reflow identity: "
                            ..uid.." ("..type(UID)..")")
    local r = INT.random()
    ACK.reflow_seal = {
        identity = UID,
        SM = UID * r,
        verifier = ACK.reflow_public_key + G2 * r
    }
    new_codec'reflow seal'
end

When("create reflow seal with identity ''",_create_reflow_seal_f)
When("create reflow seal",function() _create_reflow_seal_f('reflow identity') end)

When("create reflow signature",function()
	empty 'reflow signature'
	have 'reflow seal'
	have 'issuer public key'
	havekey 'reflow'
	havekey 'credential'
	-- aggregate all credentials
	local pubcred = false
	for _, v in pairs(ACK.issuer_public_key) do
	   if not pubcred then
	      pubcred = v
	   else
	      pubcred = {
		 ['alpha'] = pubcred.alpha + v.alpha,
		 ['beta'] = pubcred.beta + v.beta
	      }
	   end
	end
	local p, z =
	   ABC.prove_cred_uid(
	      pubcred,
	      ACK.credentials,
	      ACK.keyring.credential,
	      ACK.reflow_seal.identity
	   )
	ACK.reflow_signature = {
	   identity = ACK.reflow_seal.identity,
	   signature = ACK.reflow_seal.identity * ACK.keyring.reflow,
	   proof = p,
	   zeta = z
	}
	new_codec('reflow signature')
end)

When("prepare credentials for verification",function()
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
end)

IfWhen("verify reflow signature credential",function()
        have 'reflow_signature'
        have 'verifiers'
        have 'reflow_seal'
        zencode_assert(
            ABC.verify_cred_uid(
                ACK.verifiers,
                ACK.reflow_signature.proof,
                ACK.reflow_signature.zeta,
                ACK.reflow_seal.identity
            ),
            'Signature has an invalid credential to sign'
        )
end)

IfWhen("verify reflow signature fingerprint is new", function()
    have 'reflow_signature'
    have 'reflow_seal'
    if not ACK.reflow_seal.fingerprints then
        return
    end
    zencode_assert(
        not ACK.reflow_seal.fingerprints[ACK.reflow_signature.zeta],
        'Signature fingerprint is not new'
    )
end)

When("add reflow fingerprint to reflow seal",function()
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
end)

When("add reflow signature to reflow seal",function()
        have 'reflow_seal'
        have 'reflow_signature'
        ACK.reflow_seal.SM =
            ACK.reflow_seal.SM + ACK.reflow_signature.signature
end)

IfWhen("verify reflow seal is valid",function()
        have 'reflow_seal'
        zencode_assert(
            ECP2.miller(ACK.reflow_seal.verifier, ACK.reflow_seal.identity)
            ==
            ECP2.miller(G2, ACK.reflow_seal.SM),
            "reflow seal doesn't validates"
        )
end)

When("aggregate reflow seal array in ''",function(arr)
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
	new_codec'reflow seal'
end)

--------------------
-- MATERIAL PASSPORT
--
-- Simplified flow to generate and verify material passports, which
-- are a particular use-case of reflow signatures. Statements here do
-- implicit things and reduce complexity of operations, in particular
-- there is no multi-party computation in this process so credential
-- use is omitted.


-- aggregation supports single element arrays and fixes off-by-one
local function _aggregate_array(arr)
   assert(isarray(arr), "Cannot aggregate invalid array", 2)
   local res = arr[1]
   if #arr > 1 then
	  for i = 2, #arr do
		 res = res + arr[i]
	  end
   end
   return(res)
end

When("create material passport of ''",function(obj)
	  local key = havekey'reflow'
	  local cred = have'credentials'
	  local id = have'reflow identity'
	  local issuer_pub = have'issuer public key'
	  -- object to sign
	  local src = have(obj)
	  empty('material passport')
	  -- append agent id to track and trace
	  if not ACK.fingerprints then ACK.fingerprints = { } end
	  table.insert(ACK.fingerprints, id)
	  -- calculate object uid
	  local UID = _makeuid(src) -- reflow unique ID of object
	  -- calculate signing uid (aggregation of all fingerprints)
	  local SID = UID + _aggregate_array(ACK.fingerprints)
	  local r = INT.random() -- blinding factor
	  local p, z = ABC.prove_cred_uid(issuer_pub, cred,
									  ACK.keyring.credential, SID)
	  ACK.material_passport = {
		 seal = {
			identity = UID,
			fingerprints = ACK.fingerprints, -- optional
			SM = (SID * r) + (SID * key), -- blinding factor
			verifier = (G2 * r) + (G2 * key)
		 },
		 proof = p,
		 zeta = z
	  }
	  new_codec'material passport'
end)

IfWhen("verify material passport of ''",function(obj)
	  local src = have(obj)
	  local mp = have'material passport'
	  local pub = have'issuer public key'
	  if not zencode_assert(mp.seal.fingerprints,
				 "No fingerprints found in material passport seal: "..obj) then return end
	  local UID = _makeuid(src)
	  if not zencode_assert(UID == mp.seal.identity,
				 "Object does not match material passport identity (needs track and trace?): "..obj) then return end
	  local SID = UID + _aggregate_array(mp.seal.fingerprints)
	  if not zencode_assert(
		 ECP2.miller(mp.seal.verifier, SID)
		 ==
		 ECP2.miller(G2, mp.seal.SM),
		 "Object matches, but seal is invalid: "..obj) then return end
	  if not zencode_assert(
		 ABC.verify_cred_uid(pub, mp.proof, mp.zeta, SID),
		 "Object and seal are valid, but proof of issuance fails: "..obj) then return end
end)

-- Complex check calculates UID of object and compares to seal, if
-- correct then validates, else searches for .track array of seals and
-- calculates aggregated UID, if correct then validates
IfWhen("verify material passport of '' is valid",function(obj)
	  have(obj)
	  have(obj..'.seal')
      -- TODO
end)
