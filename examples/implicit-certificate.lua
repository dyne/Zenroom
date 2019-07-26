-- ECQV (Qu-Vanstone Implicit Certificate Scheme)
-- Zenroom implementation by Jaromil
-- based on "Standards for Efficient Cryptogrpahy"
-- specification SEC 4 v1.0 retrieved from www.secg.org

-- setup
ECP = require_once'zenroom_ecp'
random = RNG.new()
order = ECP.order()
G = ECP.generator()

-- typical EC key generation on G1
-- take a random big integer modulo curve order
-- and multiply it by the curve generator

function keygen(rng,modulo)
   local key = INT.new(rng,modulo)
   return { private = key,
   			public = key * G }
end

-- generate the certification request
certreq = keygen(random,order)
-- certreq.private is preserved in a safe place
-- certreq.public is sent to the CA along with a declaration
declaration = { requester = "Alice",
				statement = "I am stuck in Wonderland" }
print("Declaration:")
I.print(declaration)
-- Requester sends to CA -->

-- ... once upon a time ...

-- --> CA receives from Requester
-- keypair for CA (known to everyone as the Mad Hatter)
CA = keygen(random,order)

-- from here the CA has received the request
certkey = keygen(random,order)
-- certkey.private is sent to requester
-- certkey.public is broadcasted

-- public key reconstruction data
certpub = certreq.public + certkey.public
-- the certification is serialized (could use ASN-1 or X509)
certification = { public = certpub,
				  requester = declaration.requester,
				  statement = declaration.statement,
				  certifier = str("Mad Hatter") }
CERT = sha256(OCTET.serialize(certification))
CERThash = INT.new(CERT)
-- private key reconstruction data
certpriv = (CERThash * certkey.private + CA.private)
-- CA sends to Requester certpriv and CERThash
-- eventually CA broadcasts certpub and CERThash

-- ... on the other side of the mirror ...

-- Alice has received from the CA the certpriv and CERT
-- which can be used to create a new CERTprivate key
CERTprivate = (CERThash * certreq.private + certpriv) % order

-- Anyone may receive the certpub and CERThash and, knowing the CA
-- public key, can recover the same CERTpublic key from them
CERTpublic  = certpub * CERThash + CA.public

-- As a proof here we generate the public key in a standard way,
-- multiplying it by the curve generator point, then check equality
assert(CERTpublic == G * CERTprivate)
print "Certification by Mad Hatter:"
I.print({ private = CERTprivate:octet():hex(),
		  public  =  CERTpublic:octet():hex()    })
