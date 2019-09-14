# Smart contracts in human language

Zenroom is software inspired by the [language-theoretical security](http://langsec.org) research and it allows to express cryptographic operations in a readable domain-specific language called **Zencode**.

For the theoretical background see the [Zencode Whitepaper](https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf).

For an introduction see this blog post: [Smart contracts for the English speaker](https://decodeproject.eu/blog/smart-contracts-english-speaker).

Here we go with the <span class="big">**tutorial to learn the Zencode language!**</span>

# Attribute Based Credentials

![Alice in Wonderland](img/alice_with_cards-sm.jpg)

Attribute Based Credentials are a powerful and complex feature
implemented using the [Coconut crypto
scheme](https://arxiv.org/pdf/1802.07344.pdf). We start this tutorial
with the most complex functionality available in Zenroom to show how
the Zencode language really simplifies it all.

Let's imagine 3 different subjects for our scenarios:

1. **Mad Hatter** is a well known **issuer** in Wonderland
2. **Wonderland** is an open space (a blockchain!) and all inhabitants can check the validity of **proofs**
3. **Alice** just arrived: to create **proofs** she'll request a **credential** to the issuer **MadHatter** 

When **Alice** is in possession of **credentials** then she can
create a **proof** any time she wants using as input:

- the **credentials**
- her **credential keypair**
- the **verifier** by MadHatter
```cucumber
{! examples/create_proof.zen !}
```

All these "things" (credentials, proofs, etc.) are data structures that can be used as input and received as output of Zencode functions. For instance a **proof** can be print in **JSON** format and looks a bit list this:

```json
{
   "credential_proof" : {
      "pi_v" : {
         "c" : "u64:tBrCGawWYEAi55_hHIPq0JT3OaapOebSHVW0GhjJcAk",
         "rr" : "u64:J7R3FXsI2dcfyZRCqWA8fDYijG39P16LvGpX90wtCWw",
         "rm" : "u64:QoG-28CNTAY3Ir4SQqVoK1ZpTlzOnXxX6Xtq5KMIxpo"
      },
      "nu" : "u64:BA77WYvBRsc53uAyrqTjuUdptJPZbcTlzr9icizm0...",
      "sigma_prime" : {
         "h_prime" : "u64:BB9AM5xjWPxsZ47zh1WAmFymru66W6YuK...",
         "s_prime" : "u64:BAGYNM6JO0wRAGE87_-bQVuhUXeEoeJrh..."
      },
      "kappa" : "u64:GFVYsudbHOJNzPl3ZL0_VzB_DRvrPKF26OCZR9..."
   },
   "zenroom" : {
      "scenario" : "coconut", "encoding" : "url64", "version" : "1.0.0"
   }
}
```

Anyone can verify proofs using as input:

- the **credential proof**
- the **verifier** by MadHatter
```cucumber
{! examples/verify_proof.zen !}
```

What is so special about these proofs? Well!  Alice cannot be followed
by her trail of proofs: **she can produce an infinite number of
proofs, always different from one another**, for anyone to recognise
the credential without even knowing who she is.

![even the MadHatter is surprised](img/madhatter.jpg)

Imagine that once **Alice** is holding **credentials** she can enter
any room in Wonderland and drop a **proof** in the chest at its
entrance: this proof can be verified by anyone without disclosing
Alice's identity.

The flow described above is pretty simple, but the steps to setup the
**credential** are a bit more complex. Lets start using real names
from now on:

- Alice is a credential **Holder**
- MadHatter is a credential **Issuer**
- Wonderland is a public **Blockchain**
- Anyone is any peer connected to the blockchain

![Zencode flow for ABC](img/zkp_abc_flow.svg)

To add more detail, the sequence is:

![Zencode sequence for ABC](img/zkp_abc.svg)


1 **MadHatter** generates an **issuer keypair**
<table><tr><th>Input</th><th>Zencode</th><th>Output</th></tr>
<tr><td> - </td><td><pre>
{! examples/issuer_keygen.zen !}
</pre></td>
<td>issuer_keypair</td>
</tr></table>

1a **MadHatter** publishes the **verification key**
<table><tr><th>Input</th><th>Zencode</th><th>Output</th></tr>
<tr><td> issuer_keypair </td><td><pre>
{! examples/publish_verifier.zen !}
</pre></td>
<td>issuer_verifier</td>
</tr></table>

2 **Alice** generates her **credential keypair**
<table><tr><th>Input</th><th>Zencode</th><th>Output</th></tr>
<tr><td> - </td><td><pre>
{! examples/credential_keygen.zen !}
</pre></td>
<td>credential_keypair</td>
</tr></table>

3 **Alice** sends her **credential signature request**
<table><tr><th>Input</th><th>Zencode</th><th>Output</th></tr>
<tr><td> credential_keypair </td><td><pre>
{! examples/create_request.zen !}
</pre></td>
<td>credential_request</td>
</tr></table>

4 **MadHatter** decides to sign a **credential signature request**
<table><tr><th>Input</th><th>Zencode</th><th>Output</th></tr>
<tr><td> credential_request<br/>issuer_keypair </td><td><pre>
{! examples/issuer_sign.zen !}
</pre></td>
<td>issuer_signature</td>
</tr></table>

5 **Alice** receives and aggregates the signed **credential**
<table><tr><th>Input</th><th>Zencode</th><th>Output</th></tr>
<tr><td> issuer_signature<br/>credential_keypair </td><td><pre>
{! examples/aggregate_signature.zen !}
</pre></td>
<td>credential</td>
</tr></table>


## Centralized credential issuance

Lets see how flexible is Zencode.

The flow described above is for a fully decentralized issuance of
**credentials** where only the **Holder** is in possession of the
**credential keypair** needed to produce a **credential proof**.

But let's immagine a much more simple use-case for a more centralized
system where the **Issuer** provides the **Holder** with everything
ready to go to produce zero knowledge credential proofs.

The implementation is very, very simple: just line up all the **When**
blocks where the different operations are done at different times and
print the results all together!

```cucumber
Scenario coconut
Given that I am known as 'Issuer'
When I create the issuer keypair
and I create the credential keypair
and I create the credential request
and I create the credential signature
and I create the credentials
Then print the 'credentials'
and print the 'credential keypair'
```

This will produce **credentials** that anyone can take and run. Just
beware that in this simplified version of ABC the **Issuer** may
maliciously keep the **credential keypair** and impersonate the
**Holder**.



<span class="big">
<span class="mdi mdi-lightbulb-on-outline"></span>
<b>Try it on your system!</b>
</span>

Impatient to give it a spin? run Zencode scripts locally to see what
are the files produced!

Make sure that Zenroom is installed on your PC
and then go to the...

<span class="big"> <span class="mdi mdi-cogs"></span> [Shell Script
Examples](/examples/shell_scripts) </span>


# Zero Knowledge Proofs

There is more to this of course: Zencode supports several features
based on pairing elliptic curve arithmetics and in particular:

- non-interactive zero knowedge proofs (also known as ZKP or ZK-Snarks)
- threshold credentials with multiple decentralised issuers
- homomorphic encryption for numeric counters

These are all very useful features for architectures based on the
decentralisation of trust, typical of **DLT and blockchain based
systems, as well for off-line and non-interactive authentication**.

The Zencode language leverages two main scenarios, more will be
implemented in the future.

1. Attribute Based Credentials (ABC) where issuer verification keys
   represent specific credentials
2. A Petition system based on ABC and homomorphic encryption

Three more are in the work and they are:

1. Anonymous proxy validation scheme
2. Token thumbler to privately transfer numeric assets
3. Private credential revokation


# Symmetric encryption 

This is a simple tecnique to hide a secret using a common password known to all people.

```yaml
# a `message` must be set and will be used as encryption input 
# if a `header` is set will authenticate to destination
  - {when: 'I encrypt the message with '''''}
  - {when: 'I decrypt the secret message with '''''}
# encryption output is returned in `secret message`
```

Let's imagine I want to share a secret with someone and send secret messages encrypted with it:

![Zencode to encrypt with password](img/aes_crypt.svg)

I will need 3 Zencode contracts executed at different times:

**1. I generate a strong random secret**
```cucumber
{! examples/SYM01.zen !}
```
-> then save the secret output and send it

**2. I encrypt a message using this secret**
```cucumber
{! examples/SYM02.zen !}
```
-> then save the secret message and send it

**3. Who has my secret can decrypt the secret message**
```cucumber
{! examples/SYM03.zen !}
```

Of course the secret must be known by all participats and that's the
dangerous part, since it could be stolen at the moment is told.

We solve this problem using public-key cryptography, also known as a-symmetric encryption.

# Asymmetric encryption

To solve this problem we have [asymmetric encryption (or public key
cryptography)](https://en.wikipedia.org/wiki/Public-key_cryptography)
which relies on the creation of keypairs (public and private) both by
Alice and Bob.

Fortunately its pretty simple to do using Zencode.

## Key generation and exchange

```yaml
  - {when: 'I create my new keypair'}
  - {when: 'I generate my keys'}
```

![Zencode to generate asymmetric keypairs](img/ecdh_keygen.svg)

After both Alice and Bob have their own keypairs and they both know
each other public key we can move forward to do asymmetric encryption
and signatures.

**1.a Alice keygen**
```cucumber
{! examples/AES01.zen !}
```

**2.a Alice pubkey**
```cucumber
{! examples/AES02.zen !}
```

**1.b Bob keygen**
```cucumber
{! examples/AES03.zen !}
```

**2.b Bob pubkey**
```cucumber
{! examples/AES04.zen !}
```

## Public-key Encryption (ECDH)

```yaml
  # if a 'header' is set will authenticate to destination
  - {when: 'I encrypt the '''' to '''' for '''''}
  - {when: 'I decrypt the '''' from '''' to '''''}
```

![Zencode to encrypt using asymmetric keypairs](img/ecdh_crypt.svg)


**1. Alice encrypts the message using Bob's public key**
```cucumber
{! examples/AES05.zen !}
```

**2. Bob prepares a keyring with Alice's public key**
```cucumber
{! examples/AES06.zen !}
```

**3. Bob decrypts the message using Alice's public key**
```cucumber
{! examples/AES07.zen !}
```

In this basic example the session key for encryption is made combining
the private key of Alice and the public key of Bob (or
viceversa).

```cucumber
When I write 'my secret for you' in 'message'
and I write 'an authenticated message' in 'header'
```

The decryption will always check that the header hasn't changed,
maintaining the integrity of the string which may contain important
public information that accompany the secret.

## Public-key Signature (ECDSA)

```yaml
  - {when: 'I sign the '''' as '''''}
  - {when: 'I verify the '''' is authentic'}
```

![Zencode to sign using asymmetric keypairs](img/ecdsa_sign.svg)

Here we continue assuming that the keyrings are already prepared with
public/private keypairs and the public keypair of the correspondent.

**1. Alice signs a message for Bob**
```cucumber
{! examples/DSA01.zen !}
```

**1. Bob verifies the signed message from Alice**
```cucumber
{! examples/DSA02.zen !}
```

In this example Alice uses her private key to sign and authenticate a
message. Bob or anyone else can use Alice's public key to prove that
the integrity of the message is kept intact and that she signed it.

# Syntax and Memory model

Zencode contracts operate in 3 phases:

1. **Given** - validates the input
2. **When** - processes the contents
3. **Then** - prints out the results

The 3 separate blocks of code also correspond to 3 separate memory areas, sealed by some security measures.

![Zencode documentation diagram](img/zencode_diagram.png)

All data processed has first to pass the validation phase according to scenario specific data schemas.

<span class="mdi mdi-lightbulb-on-outline"></span>
**Good Practice**: start your Zencode noting down the Zenroom version you are using!

```
rule check version 1.0.0
```



## Given

### Self introduction

This affects **my** statements

```cucumber
Given I introduce myself as ''
Given I am known as ''
Given I am ''
Given I have my ''
Given I have my valid ''
```

Data provided as input (from **data** and **keys**) is all imported
automatically from **JSON** or [CBOR](https://tools.ietf.org/html/rfc7049) binary formats.

Scenarios can add Schema for specific data validation mapped to **words** like: **signature**, **proof** or **secret**.


**Data input**
```cucumber
Given I have a ''
Given I have a valid ''
Given I have a '' inside ''
Given I have a valid '' inside ''
Given I have a '' from ''
Given I have a valid '' from ''
Given the '' is valid
```

or check emptyness:

```cucumber
Given nothing
```

When **valid** is specified then extra checks are made on input value,
mostly according to the **scenario**

**Settings**
```txt
rule input encoding [ url64 | base64 | hex | bin ]
rule input format [ json | cbor ]
```

## When

Processing data is done in the when block. Also scenarios add statements to this block.

Without extensions, these are the basic functions available

```yaml
when:
  - {when: 'I append '''' to '''''}
  - {when: 'I write '''' in '''''}
  - {when: 'I set '''' to '''''}
  - {when: 'I create a random '''''}
  - {when: 'I create a random array of '''' elements'}
  - {when: 'I create a random '''' bit array of '''' elements'}
  - {when: 'I set '''' as '''' with '''''}
  - {when: 'I append '''' as '''' to '''''}
  - {when: 'I write '''' as '''' in '''''}
```

## Then

Output is all exported in JSON or CBOR

```yaml
then:
  - {then: 'print '''' '''''}
  - {then: 'print all data'}
  - {then: 'print my data'}
  - {then: 'print my data'}
  - {then: 'print my '''''}
  - {then: 'print as '''' my '''''}
  - {then: 'print my '''' as '''''}
  - {then: 'print the '''''}
  - {then: 'print as '''' the '''''}
  - {then: 'print as '''' the '''' inside '''''}
```

Settings:
```txt
rule output encoding [ url64 | base64 | hex | bin ]
rule output format [ json | cbor ]
```
