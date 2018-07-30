-- # Declaration of a valid data structure

-- First of all we declare a valid data structure according to the
-- taxonomic definition of a use-case.

-- This example takes into account the case of DECIDIM for which every
-- participant needs to disclose:
--    - his/her birthdate
--    - national ID number
--    - residential postcode

-- define the validation schema for participant's data 
participant = SCHEMA.Record {
    birthdate = SCHEMA.String,
    nationid  = SCHEMA.String,
    postcode  = SCHEMA.String
}

-- the DATA variable receives the actual DATA from participants
-- this may provene from a webform for instance, or stored data 
data = read_json(DATA, participant)
-- please note read_json also checks if the data is valid when
-- providing a validator like the one above, else it prints out
-- meaningful errors
keys = read_json(KEYS)

-- now import decidim's public key
decidim_key = ECDH.new()
decidim_key:public( base64(keys['decidim']) )

-- now import our own private key (we are the data subject)
own = ECDH.new()
own:private( base64(keys['own_private']) )

-- now calculate the session key between us and decidim
session = own:session(decidim_key)


-- encrypt our data with the session key
-- the keys stay in clear but values are encrypted
out = {}
LAMBDA.map(data,function(k,v)
			  out[k] = own:encrypt_weak_aes_cbc(
				 session,octet.from_string(v))
				 :base64()
end)

-- print out result
print(JSON.encode(out))
