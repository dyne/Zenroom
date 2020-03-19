# Crypto modeling with Zenroom and Lua

The Zenroom VM uses the Lua direct-syntax parser to securely interpret
and execute operations including complex arithmetics on Elliptic Curve
primitives [ECP module](lua/modules/ECP.html) as well Pairing
operations on twisted curves (ECP2).

The resulting scripting language is a [restricted Lua dialect](/lua)
without any external extension, customised to resemble as much as
possible the scripting language used by cryptographers in software, as
for instance Mathematica.

With Zenroom we want to lower the friction that cryptographers face
when implementing new crypto models. One can see this software as a
sort of templating system bridging the work of cryptographers and
programmers.

The [Zencode
Whitepaper](https://files.dyne.org/zenroom/Zenroom_Whitepaper.pdf)
explains in depth the issues at stake.

The intended audience of this documentation chapter are
cryptographers.

## Short path from math to production

Examples speak more than a thousand words. We will dive into two
implementations to make it evident how easy is to **go from an
academic paper to a portable implementation** running efficiently on
any platform.

### ElGamal

As a basic introduction we propose the implementation of [ElGamal
encryption
system](https://en.wikipedia.org/wiki/ElGamal_encryption). The code
below makes use of the [ECP arithmetics](lua/modules/ECP.html)
provided by Zenroom to produce ElGamal commitments useful to
zero-knowledge proofs.

```lua
G = ECP.generator()
O = ECP.order()
salt = ECP.hashtopoint("Constant random string")
secret = INT.new(sha256("Secret message to be hashed to a number"))
r = INT.modrand(O)
commitment = G * r + salt * secret
-- keygen
seckey = INT.modrand(O)
pubkey = seckey * G
-- sign
k = INT.modrand(O)
cipher = { a = G * k,
		   b = pubkey * k + commitment * secret }
-- verify
assert(cipher.b - cipher.a * seckey
	      ==
	   commitment * secret)
```

One can play around with this code already by using our [online demo](/demo).

### BLS signatures

The pairing property of some elliptiv curves can be exploited for
short signatures as defined by [Boneh-Lynn-Schacham
(BLS)](https://en.wikipedia.org/wiki/Boneh%E2%80%93Lynn%E2%80%93Shacham)
in 2001.

Here the Zenroom implementation:

```lua
msg = str("This is the authenticated message")
G1 = ECP.generator()
G2 = ECP2.generator()
O  = ECP.order()
-- keygen: δ = r.O ; γ = δ.G2
sk = INT.modrand(O)
pk = G2 * sk
-- sign: σ = δ * ( H(msg)*G1 )
sm = ECP.hashtopoint(msg) * sk
-- verify: ε(γ,H(msg)) == ε(G2,σ)
hm = ECP.hashtopoint(msg)
assert( ECP2.miller(pk, hm) == ECP2.miller(G2, sm),
        "Signature doesn't validates")
```

### One-round tripartite shared secret

This secret sharing protocol uses BLS curve pairing in a rather simple way, it was first described by Antonine Joux in the paper [A One Round Protocol for Tripartite Diffie–Hellman](http://cgi.di.uoa.gr/~aggelos/crypto/page4/assets/joux-tripartite.pdf) (2000).

Here the Zenroom demonstration of the protocol:

```lua
-- Joux’s one-round Tripartite Diffie-Hellman
-- Setup
local G1 = ECP.generator()
local G2 = ECP2.generator()
local O  = ECP.order()
-- Parties A,B,C generate random a,b,c ∈ Zr
a = INT.modrand(O)
b = INT.modrand(O)
c = INT.modrand(O)
-- Parties A,B,C broadcast to all aG, bG, cG
aG1 = G1 * a
aG2 = G2 * a
bG1 = G1 * b
bG2 = G2 * b
cG1 = G1 * c
cG2 = G2 * c
-- Theoretical proof of ε(G, G)^abc
K  = ECP2.miller(G2,  G1)  ^ ( a * b * c )
-- A computes KA = ε(bG, cG)^a
KA = ECP2.miller(bG2, cG1) ^ a
-- B computes KB = ε(aG, cG)^b
KB = ECP2.miller(aG2, cG1) ^ b
-- C computes KC = ε(aG, bG)^c
KC = ECP2.miller(aG2, bG1) ^ c
-- Shared key is K = KA = KB = KC
assert(K == KA)
assert(K == KB)
assert(K == KC)
```

### ECQV

For a practical example we will now use the Zenroom implementation of
the [Elliptic Curve Qu-Vanstone
(ECQV)](https://www.secg.org/sec4-1.0.pdf) scheme also known as
"[Implicit
Certificate](https://en.wikipedia.org/wiki/Implicit_certificate)" and
widely used by Blackberry technologies.

#### Mathematical Formula

![ECQV mathematical formula](img/ecqv.png)

#### Zenroom Implementation

```lua
G = ECP.generator()
function rand() -- random modulo
	return BIG.modrand(ECP.order())
end
-- make a request for certification
ku = BIG.modrand(ECP.order())
Ru = G * ku
-- keypair for CA
dCA = BIG.modrand(ECP.order()) -- private
QCA = G * dCA       -- public (known to Alice)
-- from here the CA has received the request
k = BIG.modrand(ECP.order())
kG = G * k
-- public key reconstruction data
Pu = Ru + kG
declaration =
	{ public = Pu:octet(),
      requester = str("Alice"),
      statement = str("I am stuck in Wonderland.") }
declhash = sha256(OCTET.serialize(declaration))
hash = BIG.new(declhash, ECP.order())
-- private key reconstruction data
r = (hash * k + dCA) % ECP.order()
-- verified by the requester, receiving r,Certu
du = (r + hash * ku) % ECP.order()
Qu = Pu * hash + QCA
assert(Qu == G * du)
```

## Elliptic Curve Point arithmetics

The brief demonstration above shows how easy it can be to implement a
cryptographic scheme in Zenroom's Lua dialect, which gives immediately
the advantage of a frictionless deployment on all targets covered by
our VM.

Arithmetic operations also involving [Elliptic Curve Points
(ECP)](/lua/modules/ECP.html) are applied using simple operators on
[BIG integers](/lua/modules/BIG.html).

All this is possible without worrying about library dependencies, OS
versioning, interpreter's availability etc.

# Main advantages of this approach

Putting the **mathematical formula and the code side by side** while using
the same variable names greatly helps to review the correctness of the
implementation.

The tooling inherited from Zenroom allows to swiftly build test
coverage and benchmarks.

Future Zenroom developments will improve the **provability of the
calculations and their results**, as well provide testing techniques as
fuzzing: this will automatically benefit all implementations.

**Cryptographers can work independently from programmers**, by modeling
their formulas using their best known tools and then provide the
script as a payload to be uploaded inside the VM.

System integrators can work on [embedding Zenroom as a VM](/wiki/how-to-embed)
without worrying about cryptographic libraries APIs and moving
dependencies required by the cryptographic implementations.

All in all, by using Zenroom your cryptographic model implementation
is **ready for an accellerating future where crypto technologies will
grow in diversity and possibilities**!
