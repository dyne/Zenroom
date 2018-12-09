-- Zencode for Implicit Certificates (ECQV)

-- stateful globals
-- TODO: use finite state machine
whoami = nil
declared = nil
certificate = nil
declaration = nil
whois = nil
authority = nil

-- crypto setup
random = RNG.new()
order = ECP.order()
G = ECP.generator()
KDF_rounds = 10000

schemas = {

   certificate = S.record {
	  objid = S.string,
	  private = S.Optional(S.big),
	  public = S.ecp,
	  hash = S.big,
	  from = S.string,
	  authkey = S.ecp
   },

   certificate_hash = S.Record {
	  public = S.ecp,
	  requester = S.string,
	  statement = S.string,
	  certifier = S.string
   },

   declaration = S.record {
	  from = S.string,
	  to = S.string,
	  statement = S.string,
	  public = S.ecp
   },

   declaration_keypair = S.record {
	  objid = S.string,
	  requester = S.string,
	  statement = S.string,
	  public = S.ecp,
	  private = S.hex
   },

   keyring = S.record {
	  private = S.hex,
	  public = S.ecp
   }
}

local function keygen()
   local key = INT.new(random,order)
   return { private = key,
            public = key * G }
end

-- request
f_hello = function(nam) whoami = nam end
Given("I introduce myself as ''", f_hello)
Given("I am known as ''", f_hello)

f_havekey = function (keytype, keyname)
   local kn = keyname or whoami
   -- x(0,"have "..keytype.." key for "..keyname)
   keypair = L.property(kn)(JSON.decode(KEYS))
   assert(validate(keypair,schemas['keyring']),
		  "Invalid keyring for "..kn)
   assert(keypair[keytype],
		  "Key "..keytype.." not found in "..kn.." keyring")
   _G['keyring'] = keypair -- explicit global state
end

function f_certhash(t)
   assert(validate(t,schemas['certificate_hash']),
		  "Invalid input to generate a certificate hash")
   return INT.new(sha256(OCTET.serialize(I.spy(t))))
end

Given("I have the '' key '' in keyring", f_havekey)
Given("I have my '' key in keyring", f_havekey)

When("I declare to '' that I am ''",   function (auth,decl)
		 -- declaration
		 if not declared then declared = decl
		 else declared = declared .." and ".. decl end
		 -- authority
		 authority = auth
end)
When("I issue my declaration", function()
		local certreq = keygen()
		declaration = {
		   zencode = VERSION,
		   objid = 'declaration',
		   public = {
			  from = whoami,
			  to = authority,
			  statement = declared,
			  public = hex(certreq.public) },
		   keypair =  {
			  public = hex(certreq.public),
			  private = hex(certreq.private) }
		}
end)
Then("print my ''", function (what)
		assert(_G[what], "Cannot print, data not found: "..what)
		write_json(_G[what])
end)

-- issue
Given("I receive a '' from ''", function(obj, sender)
		 local d = L.property(obj)(JSON.decode(DATA))
		 assert(validate(d,schemas[obj]),
				"Invalid "..obj.." (expected from "..sender..")")
		 assert(d.from == sender,
				"Invalid "..obj.." sent from "..d.from..
				   " instead of "..sender)
		 _G[obj] = d -- set state		 
end)

When("I issue my certificate", function()
		-- read global states set before
		local certkey = keygen()
		-- local declaration = _G['declaration']
		-- local keyring     = _G['keyring']
		local certreq = ECP.new(declaration.public)
		-- generate the certificate
		local certpub = certreq + certkey.public
		local certhash = f_certhash({ public    = hex(certpub),
									  requester = declaration.from,
									  statement = declaration.statement,
									  certifier = whoami })
		local certpriv = (certhash * certkey.private + keyring.private)
		-- format the certificate
		certificate = {
		   public = {
			  objid = 'certificate.ECQV',
			  public  = hex(certpub),
			  hash    = hex(certhash),
			  authkey = keyring.public,
			  from = whoami
		   },
		   private = {
			  objid = 'certificate.ECQV',
			  public  = hex(certpub),
			  private = hex(certpriv),
			  hash    = hex(certhash),
			  authkey = keyring.public,
			  from = whoami
		   }
		}
end)

-- save
-- keyring contains declaration's keypair
When("I verify the ''", function(verif)
		-- we only know how to verify declarations with certificates
		-- assert(obj == "declaration" and verif == "certificate",
		-- 	   "Cannot verify "..obj.." with "..verif)
		certificate = L.property(verif)(JSON.decode(DATA))
		assert(validate(certificate,schemas[verif]), "Invalid "..verif)
		-- explicit conversions
		local v = { certhash = INT.new(certificate.hash),
					declpriv = INT.new(keyring.private),
					certpriv = INT.new(certificate.private),
					capub    = ECP.new(certificate.authkey),
					certpub  = ECP.new(certificate.public)  }
		v.checkpriv = (v.certhash * v.declpriv + v.certpriv) % order
		v.checkpub  =  v.certpub  * v.certhash + v.capub
		assert(v.checkpub == (G * v.checkpriv),
			   "Verification failed: "..verif.." is not valid:\n"..DATA)
		-- publish signed declaration
		_G['declaration'] = {
		   hash = certificate.hash,
		   authkey = certificate.authkey,
		   certificate = certificate.public }
end)

-- verify
-- keyring contains authority's keypair
Given("that '' declares to be ''",function(who, decl)
		 -- declaration
		 if not declared then declared = decl
		 else declared = declared .." and ".. decl end
		 whois = who
end)
Given("declares also to be ''", function(decl)
		 assert(who ~= "", "The subject making the declaration is unknown")
		 -- declaration
		 if not declared then declared = decl
		 else declared = declared .." and ".. decl end
end)
When("I receive the '' from ''", function(obj, who)
		local d = L.property(obj)(JSON.decode(DATA))
		assert(validate(d,schemas[obj]), "Invalid schema: "..obj)
		assert(d.from == who, "The "..obj.." is not from "..who)
		_G[obj] = d -- set state
end)
When("I use the '' to encrypt ''", function(what,content)
		local cipher = { iv = random:octet(16) }
		if what == "certificate" then
		   local CERThash = f_certhash({ public    = certificate.public,
										 requester = whois,
										 statement = declared,
										 certifier = certificate.from })
		   error(certificate.hash)
		   error(CERThash)
		   error(type(hex(certificate.hash)))
		   error(type(CERThash:octet()))
		   error(#certificate.hash)
		   error(#CERThash)
		   assert(certificate.hash == CERThash, "Incorrect certificate hash")
		   local CERTpublic = ECP.new(certificate.public) * CERThash + ECP.new(certificate.authkey)
		   -- calculate shared session key
		   session_raw = ( INT.new(keyring.private) % order) * CERTpublic
		   session = ECDH.pbkdf2(HASH.new('sha256'),session_raw,random:octet(64),KDF_rounds,32)
		end

		cipher.text,cipher.checksum =
		   ECDH.aead_encrypt(session, content, random:octet(16), keyring.public)
		-- cipher = map(cipher,hex)
		cipher.objid = what ..".ciphermsg"
		_G['message'] = cipher
end)
