-- Zencode for Implicit Certificates (ECQV)

-- stateful globals
-- TODO: use finite state machine
whoami = nil
declared = nil
certificate = nil
declaration = nil
whois = nil
authority = nil

function f_certhash(t)
   assert(validate(t,schemas['certificate_hash']),
		  "Invalid input to generate a certificate hash")
   return INT.new(sha256(OCTET.serialize(t)))
end

When("I issue my implicit certificate declaration", function()
		local certreq = ZEN.keygen()
		data = data or {} -- JSON.decode(DATA)
		ZEN.data.conjoin(data, 'certreq', 'declaration',
					{ schema = "declaration",
					  from = whoami,
					  to = authority,
					  statement = declared,
					  public = hex(certreq.public) })
		ZEN.data.conjoin(data, 'certreq', 'keypair',
					{ schema = "keypair",
					  public = hex(certreq.public),
					  private = hex(certreq.private) })
end)
Then("print my ''", function (what)
		assert(_G[what], "Cannot print, data not found: "..what)
		local t = type(_G[what])
		if t == "table" then write_json(_G[what])
		elseif iszen(t) or t == "string" then
		   print(_G[what])
		else
		   error("Cannot print '"..what.."' data type: "..t)
		end
end)

When("I issue an implicit certificate", function()
		-- read global states set before
		local certkey = ZEN.keygen()
		local certreq = ECP.new(declaration.public)
		-- generate the certificate
		local certpub = certreq + certkey.public
		local certhash = f_certhash({ public    = hex(certpub),
									  requester = declaration.from,
									  statement = declaration.statement,
									  certifier = whoami })
		local certpriv = (certhash * certkey.private + keypair.private)
		-- format the certificate
		ZEN.data.conjoin(data, 'certificate', 'public',
					{ schema = 'certificate',
					  public  = hex(certpub),
					  hash    = hex(certhash),
					  authkey = keypair.public,
					  from = whoami })
		ZEN.data.conjoin(data, 'certificate', 'private',
					{ schema = 'certificate',
					  public  = hex(certpub),
					  private = hex(certpriv),
					  hash    = hex(certhash),
					  authkey = keypair.public,
					  from = whoami })
end)

-- save
-- keypair contains declaration's keys
When("I verify the implicit certificate ''", function(verif)
		-- we only know how to verify declarations with certificates
		-- assert(obj == "declaration" and verif == "certificate",
		-- 	   "Cannot verify "..obj.." with "..verif)
		-- certificate = L.property(verif)(JSON.decode(DATA))
		data = data or JSON.decode(DATA)
		certificate = ZEN.data.check(data,verif)
		assert(validate(certificate,schemas[verif]), "Invalid "..verif)
		-- explicit conversions
		local v = { certhash = INT.new(certificate.hash),
					declpriv = INT.new(keypair.private),
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

When("I use the '' to encrypt ''", function(what,content)
		local cipher = { iv = random:octet(16) }
		if what == "certificate" then
		   local CERThash = f_certhash({ public    = certificate.public,
										 requester = whois,
										 statement = declared,
										 certifier = certificate.from })
		   -- TODO: correct hash comparison
		   -- I.print(certificate.hash)
		   -- I.print(CERThash)
		   -- I.print(type(hex(certificate.hash)))
		   -- I.print(type(CERThash:octet()))
--		   assert(certificate.hash == CERThash, "Incorrect certificate hash")
		   local CERTpublic = ECP.new(certificate.public) * CERThash + ECP.new(certificate.authkey)
		   -- calculate shared session key
		   session_raw = ( INT.new(keypair.private) % order) * CERTpublic
		   session = ECDH.kdf2(HASH.new('sha256'),session_raw) -- ,random:octet(64),KDF_rounds,32)
		end
		-- header is in the ciphertext for increased privacy (no metadata)
		local text = str(MSG.pack({ from = whoami,
									pubkey = keypair.public,
									text = content }))

		cipher.text,cipher.checksum =
		   ECDH.aesgcm_encrypt(session, text, random:octet(16), str("Zencode"))

		cipher = map(cipher,hex)
		cipher.schema = "ciphertext"
		ZEN.data.conjoin(data,"message","ciphertext",cipher)
		-- cipher.header = header -- hex(header)
		-- _G['message'] = I.spy(cipher)
end)
