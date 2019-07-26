-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
   ZEN.assert(validate(t,schemas['certificate_hash']),
		  "Invalid input to generate a certificate hash")
   return INT.new(sha256(OCTET.serialize(t)))
end

When("I issue my implicit certificate request ''", function(decl)
		local certreq = ZEN.keygen()
		data = data or ZEN.data.load()
		ZEN.data.add(data, decl.."_public",
					{ schema = "declaration",
					  from = whoami,
					  to = authority,
					  statement = declared,
					  public = hex(certreq.public) })
		ZEN.data.add(data, decl.."_keypair",
					{ schema = "keypair",
					  public = hex(certreq.public),
					  private = hex(certreq.private) })
end)
Then("print my ''", function (what)
		ZEN.assert(_G[what], "Cannot print, data not found: "..what)
		local t = type(_G[what])
		if t == "table" then write_json(_G[what])
		elseif iszen(t) or t == "string" then
		   print(_G[what])
		else
		   error("Cannot print '"..what.."' data type: "..t)
		end
end)

When("I issue an implicit certificate for ''", function(decl)
		init_keyring(whoami)
		data = data or ZEN.data.load()
		-- read global states set before
		local declaration = data[decl]
		local certkey = ZEN.keygen()
		local certreq = ECP.new(declaration.public)
		-- generate the certificate
		local certpub = certreq + certkey.public
		local certhash = f_certhash({ public    = certpub,
									  requester = declaration.from,
									  statement = declaration.statement,
									  certifier = whoami })
		local certpriv = (certhash * certkey.private + keyring[keypair].private)
		-- format the certificate
		local certificate = { }
		ZEN.data.add(data, 'certificate_public',
					{ schema = 'certificate',
					  public  = hex(certpub),
					  hash    = hex(certhash),
					  authkey = keyring[keypair].public,
					  from = whoami })
		ZEN.data.add(data, 'certificate_private',
					{ schema = 'certificate',
					  public  = hex(certpub),
					  private = hex(certpriv),
					  hash    = hex(certhash),
					  authkey = keyring[keypair].public,
					  from = whoami })
end)

-- save
-- keypair contains declaration's keys
When("I verify the implicit certificate ''", function(verif)
		-- we only know how to verify declarations with certificates
		-- ZEN.assert(obj == "declaration" and verif == "certificate",
		-- 	   "Cannot verify "..obj.." with "..verif)
		init_keyring('declaration_keypair')
		data = data or ZEN.data.load()
		certificate = data[verif]
		ZEN.assert(validate(certificate,schemas['certificate']),
				   "Invalid implicit certificate: "..verif)
		-- explicit conversions
		local v = { certhash = INT.new(certificate.hash),
					declpriv = INT.new(keyring[keypair].private),
					certpriv = INT.new(certificate.private),
					capub    = ECP.new(certificate.authkey),
					certpub  = ECP.new(certificate.public)  }
		v.checkpriv = (v.certhash * v.declpriv + v.certpriv) % order
		v.checkpub  =  v.certpub  * v.certhash + v.capub
		ZEN.assert(v.checkpub == (G * v.checkpriv),
			   "Verification failed: "..verif.." is not valid:\n"..DATA)
		-- publish signed declaration
		ZEN.data.add(data,'declaration', {
						hash = certificate.hash,
						authkey = certificate.authkey,
						certificate = certificate.public })
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
--		   ZEN.assert(certificate.hash == CERThash, "Incorrect certificate hash")
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
