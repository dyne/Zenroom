-- ECQV (Qu-Vanstone Implicit Certificate Scheme)
-- Zenroom implementation by Jaromil
-- based on "Standards for Efficient Cryptogrpahy"
-- specification SEC 4 v1.0 retrieved from www.secg.org

requester = str("Alice")
statement = str("Let me know.")

-- setup
random = RNG.new()
order = ECP.order()
G = ECP.generator()

-- make a request for certification
ku = INT.new(random, order)
Ru = G * ku

-- keypair for CA
dCA = INT.new(random, order) -- private
QCA = G * dCA       -- public (known to Alice)

-- from here the CA has received the request
k = INT.new(random, order)
kG = G * k

-- public key reconstruction data
Pu = Ru + kG

declaration = { public = Pu:octet(),
				requester = str("Alice"),
				statement = str("Is in Wonderland.") }

I.print(declaration)
print(OCTET.serialize(declaration))

declhash = sha256(OCTET.serialize(declaration))
-- TODO: proper encapsulation x509 or ASN-1
-- declaration = Pu:octet() .. requester .. statement
hash = INT.new(declhash) -- % order
-- private key reconstruction data
r = (hash * k + dCA) % order

-- verified by the requester, receiving r,Certu
du = (r + hash * ku) % order
Qu = Pu * hash + QCA
assert(Qu == G * du)

