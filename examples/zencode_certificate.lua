-- Zencode for Implicit Certificates (ECQV)

verbosity = 1
-- debugging facility
local function x(n,s)
   if verbosity > n then
	  warn(s) end
end

-- -- stateful globals
-- keyring = {}
-- declaration = ""
-- -- certreq = {}
-- certification = nil
-- certpriv = nil
-- certpub = nil
-- random = nil
-- order = nil
-- G = nil

-- crypto setup
random = RNG.new()
order = ECP.order()
G = ECP.generator()

schema_certificate = S.record {
   requester = S.string,
   authority = S.string,
   public = S.oneof(S.hex, S.ecp),
   declaration = S.string
}

schema_certificate = S.record {
   requester = S.string,
   authority = S.string,
   declaration = S.string,
   public = S.oneof(S.hex, S.ecp) }

schema_keyring = S.record {
   private = S.string,
   public = S.string }

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
Given("I introduce myself as ''", function (nam)
		 x(0,"introduce me: "..nam)
		 whoami = nam
end)
Given("I am known as ''",         function (nam)
		 x(0,"known as "..nam)
		 whoami = nam end)
Given("I have the '' key '' in keyring", function (keytype, keyname)
		 x(0,"have "..keytype.." key for "..keyname)
         local keys = JSON.decode(KEYS) -- array of keypairs
         local keypair = L.property(keyname)(keys)
		 assert(validate(keypair,schema_keyring),
				"invalid keyring for "..keyname)
		 if not keypair then
			error("keyring not found: "..keyname)
			return nil end
		 keyring = {}
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
end)
When("I declare to '' that I am ''",   function (auth,decl)
		x(0,"declare to "..auth.." that I am "..decl)
		 -- request certificate
		 if not certreq then
			certreq = keygen(random,order) end
		 -- declaration
		 if not declaration then declaration = decl
		 else declaration = declaration .." and ".. decl end
		 -- authority
		 authority = auth
end)
Then("my '' should be valid", function (what)
		x(0,"my "..what.." is valid")
		if what == "declaration" then
		   local decl = {
			  requester = whoami,
			  authority = authority,
			  declaration = declaration,
			  public = hex(certreq.public) }
		   assert(validate(decl,schema_certificate),"invalid "..what)
		   write_json(decl)
		end
end)

-- issue
Given("I receive a valid '' from ''", function(obj, sender) debug2(obj,sender) end)

When("I send the declaration", function()
		x(0,"send declaration")
		write_json({
			  requester = whoami,
			  certreq = certreq.public:octet():hex(),
			  declaration = declaration })
end)

When("I certify the declaration", function ()
		x(0,"certify declaration")
        local certkey = keygen()
        certpub = cpub + certkey.public
        certification = { public = certpub,
                          statement = decl,
                          certifier = str("CA") }
        CERThash = hash_certificate(certification)
        certpriv = (CERThash * certkey.private + CA.private) % order
end)

Then("certificate should be valid", function ()
		x(0,"validate certificate")
        -- TODO: schema check
        CERThash = hash_certificate(certificate)
        CERTprivate = (CERThash * certreq.private + certpriv) % order
        CERTpublic  = certpub * CERThash + CA.public
        assert(CERTpublic == G * CERTprivate, "Certificate was expected to be valid, but is not")
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
    Then my 'declaration' should be valid

  Scenario 'issue': Receive a declaration request and issue a certificate
    Given that I am known as 'Mad Hatter'
    and I receive a 'declaration' from 'Alice'
    and I have the 'private' key 'Mad Hatter' in keyring
    When the 'declaration' by 'Alice' is true
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
