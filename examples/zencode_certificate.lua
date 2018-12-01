-- Zencode for Implicit Certificates (ECQV)

verbosity = 1
-- debugging facility
local function x(n,s)
   if verbosity > n then
	  warn(s) end
end

-- stateful globals
-- TODO: use finite state machine
whoami = nil
keyring = nil
declared = nil
certreq = nil
certificate = nil
certpub = nil
certpriv = nil

-- crypto setup
random = RNG.new()
order = ECP.order()
G = ECP.generator()

schemas = { certificate = S.record {
			   certpriv = S.OneOf( S.string, S.big),
			   certpub = S.ecp,
			   certhash = S.OneOf( S.hex, S.big),
			   issuer = S.string },
			declaration = S.record {
			   requester = S.string,
			   authority = S.string,
			   declared = S.string,
			   public = S.ecp },
			keyring = S.record {
			   private = S.string,
			   public = S.ecp }
		  }

function keygen()
   local key = INT.new(random,order)
   return { private = key,
            public = key * G }
end

function hash_certificate(cert)
   local CERT = sha256(OCTET.serialize(cert))
   return(INT.new(CERT, order))
end

function certify(cpub, decl)
   -- TODO: should be taken from KEYS
   local CA = keygen()
   local certkey = keygen()
   certpub = cpub + certkey.public
   certification = { public = certpub,
						  statement = decl,
						  certifier = str("CA") }
   local CERT = sha256(OCTET.serialize(certification))
   local CERThash = hash_certificate(certification)
   certpriv = (CERThash * certkey.private + CA.private) % order
end

function declare(decl)
end

function debug1(arg)
   print("debug: " .. arg)
end
function debug2(arg1,arg2)
   print("debug2: " .. arg1 .." "..arg2)
end

-- steps

-- request
f_hello = function(nam) whoami = nam end
Given("I introduce myself as ''", f_hello)
Given("I am known as ''", f_hello)

f_havekey = function (keytype, keyname)
   local keyname = keyname or whoami
   x(0,"have "..keytype.." key for "..keyname)
   local keys = JSON.decode(KEYS) -- array of keypairs
   local keypair = L.property(keyname)(keys)
   assert(validate(keypair,schemas['keyring']),
		  "invalid keyring for "..keyname)
   if not keypair then
	  error("keyring not found: "..keyname)
	  return nil end
   keyring = {}
   -- saved in keyring
   if keytype == "private" or keytype == "public" then
	  keyring[keytype] = L.property(keytype)(keypair)
   else
	  error("invalid keytype: "..keytype)
	  return nil
   end
   if keytype == "public" then
	  -- check public key validity
	  ECP.new(hex(keyring[keytype]))
   end
end

Given("I have the '' key '' in keyring", f_havekey)
Given("I have my '' key in keyring", f_havekey)

When("I declare to '' that I am ''",   function (auth,decl)
		x(0,"declare to "..auth.." that I am "..decl)
		 -- request certificate
		 if not certreq then
			certreq = keygen(random,order) end
		 -- declaration
		 if not declared then declared = decl
		 else declared = declared .." and ".. decl end
		 -- authority
		 authority = auth
end)
When("I issue my certificate", function()
		-- state declaration should be set
		certkey = keygen(random, order)
		declpub = ECP.new(declaration.public)
		certpub = declpub + certkey.public
		local cert = { public = hex(certpub),
					   requester = declaration.requester,
					   statement = declaration.statement,
					   certifier = whoami }
		local certhash = INT.new(sha256(OCTET.serialize(cert)),order)
		certpriv = certhash * certkey.private + INT.new(hex(keyring.private))
		-- set state 
		certificate = { certpriv = hex(certpriv),
						certpub = hex(certpub),
						certhash = hex(certhash),
						issuer = whoami	}
		write_json(certificate)
end)
When("I issue my declaration", function()
		declaration = {
		   requester = whoami,
		   authority = authority,
		   declared = declared,
		   public = hex(certreq.public) }
		write_json(declaration)
end)
Then("my '' should be valid", function (what)
		x(0,"my "..what.." should be valid")
		local schema = schemas[what]
		if not schema then
		   error("Don't know how to validate: "..what)
		else
		   assert(validate(_G[what],schema), "Schema validation failed on: ".. what)
		end
end)

-- issue
Given("I receive a '' from ''", function(obj, sender)
		 certificate = nil
		 declaration = nil
		 x(0,"receive "..obj.." from "..sender)
		 if obj == "declaration" then
			local data = JSON.decode(DATA)
			local decl = data.declaration
			assert(decl.requester == sender,
				   "declaration expected from "..sender
					  .." but is from "..decl.requester.." instead")
			assert(validate(decl,schemas['declaration']),"invalid declaration from "..sender)
			declaration = decl -- set state
		 elseif obj == "certificate" then
			local data = JSON.decode(DATA)
			local cert = data.certificate
			assert(cert.issuer == sender,
				   "certificate expected from "..sender
					  .." but is from "..cert.issuer.." instead")
			assert(validate(cert,schemas['certificate']),"invalid certificate from "..sender)
			certificate = cert -- set state
		 end
end)


-- execution
ZEN:begin(verbosity)

request = [[
Feature: Produce a verifiable 'certificate' for a 'declaration'
  In order to have a 'declaration' certified
  As a 'participant' who knows an 'authority'
  Or as an 'authority' who is also a 'participant'
  I want to make a 'declaration' and request its 'certificate'
  I want to verify a 'declaration' using its 'certificate'
  I want to communicate privately with any other 'participant'

  Scenario 'request': Make my declaration and request certificate
    Given that I introduce myself as 'Alice'
    and I have the 'public' key 'Mad Hatter' in keyring
    When I declare to 'Mad Hatter' that I am 'lost in Wonderland'
    and I issue my declaration
    Then my 'declaration' should be valid

  Scenario 'issue': Receive a declaration request and issue a certificate
    Given that I am known as 'Mad Hatter'
    and I receive a 'declaration' from 'Alice'
    and I have my 'private' key in keyring
    When the 'declaration' by 'Alice' is true
    and I issue my certificate
    Then my 'certificate' should be valid

  Scenario 'save': Receive a certificate of a declaration and save it
    Given I receive a 'certificate' from 'Mad Hatter'
    and I have the 'private' key 'declaration' in keyring
    When I verify the 'declaration' with its 'certificate'
    Then my 'certificate' should be valid

  Scenario 'verify': Verify a declaration with its certificate
    Given I receive a 'declaration' from 'Alice'
    and I receive a 'certificate' from 'Mad Hatter'
    and I have the 'public' key 'Mad Hatter' in keyring
    When I verify the 'declaration' with its 'certificate'
    Then the 'certificate' should be valid

]]

ZEN:parse(request)

ZEN:run()
