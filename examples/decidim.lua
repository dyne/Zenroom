-- # Declaration of a valid data structure

-- First of all we declare a valid data structure according to the taxonomic definition of a use-case.

-- This example takes into account the case of DECIDIM for which every participant needs to disclose:
--    - his/her birthdate
--    - national ID number
--    - residential postcode

-- define the validation schema for participant's data 
participant = schema.Record {
    birthdate = schema.String,
    nationid  = schema.String,
    postcode  = schema.String
}

-- the DATA variable receives the actual DATA from participants
-- this may provene from a webform for instance, or stored data 
data = import_json(DATA, participant)
-- checks if the data is valid, else print out meaningful errors
keys = import_json(KEYS)

decidim_key = ecdh.new()
-- import decidim's public key
decidim_key:public(
   octet.from_base64(keys['decidim']))

own = ecdh.new()
own:private(octet.from_base64(keys['own_private']))

session = own:session(decidim_key)


-- key = keypair:session("secret key")
-- encrypt the data with the key
out = {}
fun.map(data,function(k,v)
		 out[k] = own:encrypt(
			session,octet.from_string(v))
			:base64()
    end)
print(json.encode(out))
