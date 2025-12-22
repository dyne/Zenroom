--[[
--This file is part of zenroom
--
--Copyright (C) 2023-2025 Dyne.org foundation
--
--designed, written and maintained by:
--Rebecca Selvaggini, Alberto Lerda and Denis Roio
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
--]]

local sd_jwt = {}

function sd_jwt.prepare_dictionary(obj)
   -- values in input may be string, number or bool
   local fun = function(v)
	  local res
	  local tv <const> = type(v)
	  if tv == 'string' then return v
	  elseif tv == 'number' then res = v
	  elseif tv == 'zenroom.time' then
		 res = tonumber(tostring(v))
		 if tostring(res) ~= tostring(v) then
			-- safety check on some conversions
			error("Invalid conversion in SD-JWT value: "..tv)
		 end
	  elseif tv == 'zenroom.big' then
		 res = tonumber(v:decimal())
		 if tostring(res) ~= tostring(v) then
			error("Invalid conversion in SD-JWT value: "..tv)
		 end
	  elseif tv == 'zenroom.float' then
		 res = tostring(v)
		 if tostring(res) ~= tostring(v) then
			error("Invalid conversion in SD-JWT value: "..tv)
		 end
	  elseif tv == 'zenroom.octet' then res = v:str()
	  elseif tv == 'boolean' then res = v
      -- elseif iszen(tv) then res = v:octet():str()
	  else
 		 error("Invalid value found in SD-JWT array: "..tv)
	  end
	  return res
   end
   return deepmap(fun, obj)
end

-- Given as input a "disclosure array" of the form {salt, key, value}
-- Return: disclosure = the array in octet form
--         hashed = the sha256 digest of the encoded array (for _sd)
--         encoded_dis = the url64+json encoding of the input array (used just for testing)
function sd_jwt.create_disclosure(dis_arr)
    -- TODO: disclosure of disctionary

    local encoded_dis <const> =
        O.from_string(
            JSON.raw_encode(
                sd_jwt.prepare_dictionary(dis_arr), true)):url64()
    local disclosure = {}
    for i = 1, #dis_arr do
        if type(dis_arr[i]) == 'table' then
            disclosure[i] = deepmap(function(o) return O.from_string(o) end, dis_arr[i])
        elseif type(dis_arr[i]) == 'string' then
            disclosure[i] = O.from_string(dis_arr[i])
        else
            disclosure[i] = dis_arr[i]
        end
    end
    local hashed = O.from_string(sha256(encoded_dis):url64())
    return  disclosure, hashed, encoded_dis
end

--[[ JWT reserved claim names (see Section 4.1 and Section 5 of RFC7519)
"iss" (Issuer) Claim
"sub" (Subject) Claim
"aud" (Audience) Claim
"exp" (Expiration Time) Claim
"nbf" (Not Before) Claim
"iat" (Issued At) Claim
"jti" (JWT ID) Claim
"typ" (Type) Header Parameter
"cty" (Content Type) Header Parameter
]]
local JWT_RESERVED_CLAIMS = {"iss", "sub", "aud", "exp", "nbf", "iat", "jti", "typ", "type", "cty", "cnf"}

local NON_SELECTIVELY_DISCLOSABLE_CLAIMS = {"iss", "iat", "exp", "cnf", "type", "_sd", "_sd_alg"}

-- Given as input a selective disclosure request
-- Return a table containing two keys:
--        payload = the jwt containing disclosable object (the credential to be signed by the issuer)
--        disclosures = the list of disclosure arrays
function sd_jwt.create_sd(sdr)
    local disclosures = {}
    local jwt_payload = {
        _sd_alg = O.from_string("sha-256"),
        _sd = {}
    }
    for _, f in pairs(sdr.fields) do
        local f = f:str()
        local encode = nil
        if type(sdr.object[f]) == 'table' then
            encode = deepmap(function(o) return o:str() end, sdr.object[f])
        elseif type(sdr.object[f]) == 'zenroom.octet' then
            encode = sdr.object[f]:str()
        else
            encode = sdr.object[f]
        end
        local disclosure_arr = {
            O.random(16):url64(),
            f,
            encode
        }
        local disclosure, hashed = sd_jwt.create_disclosure(disclosure_arr)

        disclosures[#disclosures+1] = disclosure
        jwt_payload._sd[#jwt_payload._sd+1] = hashed
    end
    for _, rc in pairs(JWT_RESERVED_CLAIMS) do
        jwt_payload[rc] = deepcopy(sdr.object[rc])
    end

    return {
        payload=jwt_payload,
        disclosures=disclosures,
    }
end

-- TODO: add test from section A.3 of
-- https://www.rfc-editor.org/rfc/rfc7515.html
-- WARNING: the JSON encode is not unique, so I should
-- return the base64 encoding to be sure to be able to verify it,
-- but we are in zenroom and if I print the same object I obtain the
-- same representation, thus I can keep the object and print it only
-- on export, yay!
function sd_jwt.create_jwt(payload, sk, algo)
    local header <const> = {
        alg=O.from_string(algo.IANA), -- TODO: does JWT contains .alg ?!
        typ=O.from_string("dc+sd-jwt")
    }
    local payload_str <const> = sd_jwt.prepare_dictionary(payload)
    local b64payload <const> = O.from_string(JSON.raw_encode(payload_str, true)):url64()
    local header_str <const> = sd_jwt.prepare_dictionary(header)
    local b64header <const> = O.from_string(JSON.raw_encode(header_str, true)):url64()

    local signature = algo.sign(sk, O.from_string(b64header .. "." .. b64payload))
    return {
        header=header,
        payload=payload,
        signature=signature,
    }
end

local function is_in(list, elem)
    local found = false
    for i = 1, #list do
        if list[i] == elem then
            found = true
            break
        end
    end
    return found
end

-- TODO: In the final version we should check that the sd-jwt payload contains all the mandatory claims below
-- "iss", "iat", "cnf", "type", if "_sd" => "_sd_alg"
function sd_jwt.check_mandatory_claim_names(jwt)
    local found = true
    if jwt._sd then
        if not jwt._sd_alg then
            found = false
        end
    end
    if not jwt.iss then
        found = false
    end
    return found
end

-- Check that the input is a table of three elements, where the first two object are string
-- the input should be of the form {salt, key, value}
-- we also check that the key is not in NON_SELECTIVELY_DISCLOSABLE_CLAIMS
local function disclosure_array_is_valid(arr)
    if type(arr) ~= 'table' or #arr ~= 3 then
        return false
    end
    if type(arr[1]) ~= 'string' or type(arr[2]) ~= 'string' then
        return false
    end
    if is_in(NON_SELECTIVELY_DISCLOSABLE_CLAIMS, arr[2]) then
        return false
    end
    return true
end

function sd_jwt.verify_sd_fields(jwt, disclosures)
    local match = true
    local digest_arr = jwt._sd
    local disclosures_arr <const> = sd_jwt.prepare_dictionary(disclosures)
    local claim_names = {}
    for i = 1, #disclosures_arr do
        if not disclosure_array_is_valid(disclosures_arr[i]) then
            return false
        end
        if is_in(claim_names, disclosures_arr[i][2]) then
            return false
        else
            table.insert(claim_names, disclosures_arr[i][2])
        end
        local _, hashed = sd_jwt.create_disclosure(disclosures_arr[i])
        if not is_in(digest_arr, hashed) then
            match = false
            break
        end
    end
    return match
end

return sd_jwt
