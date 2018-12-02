-- Zencode for Implicit Certificates (ECQV)

-- stateful globals
-- TODO: use finite state machine
whoami = nil
declared = nil
certificate = nil
declaration = nil
authority = nil

-- crypto setup
random = RNG.new()
order = ECP.order()
G = ECP.generator()

schemas = {

   certificate = S.record {
	  objid = S.string,
	  certpriv = S.OneOf( S.string, S.big),
	  certpub = S.hex,
	  certhash = S.OneOf( S.hex, S.big),
	  from = S.string,
	  authkey = S.hex
   },

   declaration = S.record {
	  from = S.string,
	  to = S.string,
	  declared = S.string,
	  public = S.hex
   },

   declaration_keypair = S.record {
	  objid = S.string,
	  requester = S.string,
	  declared = S.string,
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
		-- request certificate
		local certreq = keygen()
		declaration = {
		   zencode = VERSION,
		   objid = 'declaration',
		   public = {
			  from = whoami,
			  to = authority,
			  declared = declared,
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
		local declaration = _G['declaration']
		local keyring     = _G['keyring']
		local certreq = ECP.new(declaration.public)
		-- generate the certificate
		local certpub = certreq + certkey.public
		local cert = { public    = certpub,
					   requester = declaration.requester,
					   statement = declaration.statement,
					   certifier = whoami }
		local certhash = INT.new(sha256(OCTET.serialize(cert)),order)
		local certpriv = (certhash * certkey.private + keyring.private)
		-- format the certificate
		certificate = {
		   public = {
			  objid = 'certificate.ECQV',
			  certpub  = hex(certpub),
			  certhash = hex(certhash),
			  authkey = keyring.public,
			  from = whoami
		   },
		   private = {
			  objid = 'certificate.ECQV',
			  certpub  = hex(certpub),
			  certpriv = hex(certpriv),
			  certhash = hex(certhash),
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
		verif_t = L.property(verif)(JSON.decode(DATA))
		assert(validate(verif_t,schemas[verif]), "Invalid "..verif)
		-- explicit conversions
		local v = { certhash = INT.new(verif_t.certhash),
					declpriv = INT.new(keyring.private),
					certpriv = INT.new(verif_t.certpriv),
					capub    = ECP.new(verif_t.authkey),
					certpub  = ECP.new(verif_t.certpub)  }
		v.checkpriv = (v.certhash * v.declpriv + v.certpriv) % order
		v.checkpub  =  v.certpub  * v.certhash + v.capub
		assert(v.checkpub == (G * v.checkpriv),
			   "Verification failed: "..verif.." is not valid:\n"..DATA)
		-- publish signed declaration
		_G['declaration'] = {
		   hash = verif_t.certhash,
		   authkey = verif_t.authkey,
		   certificate = verif_t.certpub }
end)

-- -- execution
-- ZEN:begin(verbosity)

-- request = [[
-- Feature: Produce a verifiable 'certificate' for a 'declaration'
--   In order to have a 'declaration' certified
--   As a 'participant' who knows an 'authority'
--   Or as an 'authority' who is also a 'participant'
--   I want to make a 'declaration' and request its 'certificate'
--   I want to verify a 'declaration' using its 'certificate'
--   I want to communicate privately with any other 'participant'

--   Scenario 'request': Make my declaration and request certificate
--     Given that I introduce myself as 'Alice'
--     and I have the 'public' key 'Mad Hatter' in keyring
--     When I declare to 'Mad Hatter' that I am 'lost in Wonderland'
--     and I issue my declaration
--     Then my 'declaration' should be valid

--   Scenario 'issue': Receive a declaration request and issue a certificate
--     Given that I am known as 'Mad Hatter'
--     and I receive a 'declaration' from 'Alice'
--     and I have my 'private' key in keyring
--     When the 'declaration' by 'Alice' is true
--     and I issue my certificate
--     Then my 'certificate' should be valid

--   Scenario 'save': Receive a certificate of a declaration and save it
--     Given I receive a 'certificate' from 'Mad Hatter'
--     and I have the 'private' key 'declaration' in keyring
--     When I verify the 'declaration' with its 'certificate'
--     Then my 'certificate' should be valid

--   Scenario 'verify': Verify a declaration with its certificate
--     Given I receive a 'declaration' from 'Alice'
--     and I receive a 'certificate' from 'Mad Hatter'
--     and I have the 'public' key 'Mad Hatter' in keyring
--     When I verify the 'declaration' with its 'certificate'
--     Then the 'certificate' should be valid

-- ]]

-- ZEN:parse(request)

-- ZEN:run()
