# Smart contracts in human language

Zenroom is software inspired by the [language-theoretical
security](http://langsec.org) research which allows expression of
cryptographic operations in a readable domain-specific language called
**Zencode**.

For an explanation of the innovation brought by Zencode, see this blog post: [Smart contracts for the English speaker](https://decodeproject.eu/blog/smart-contracts-english-speaker).

Now, to learn this very simple language, lets dive into some examples.

Keep in mind that statements in yellow boxes are actual Zencode being executed.

# Symmetric encryption

This is a simple tecnique to hide a secret, using a common password known to all people.

Let's imagine two people who want to communicate secretly: Alice and Bob.

![Zencode to encrypt with password](img/aes_crypt.svg)

Here the Zencode is executed three times:

1. Alice generates a strong random password
2. Alice encrypts a message using this password
3. Bob decrypts the message using the password

Of course the password must be communicated to Bob and that's the
dangerous part, since it could be stolen at the moment is told.

# Asymmetric encryption

To solve this problem we have [asymmetric encryption (or public key
cryptography)](https://en.wikipedia.org/wiki/Public-key_cryptography)
which relies on the creation of keypairs (public and private) both by
Alice and Bob.

Fortunately, it is pretty simple to do this using Zencode.

## Key generation and exchange

![Zencode to generate asymmetric keypairs](img/ecdh_keygen.svg)

After both Alice and Bob have their own keypairs, and they both know
eachother's public key, we can move forward to do asymmetric encryption
and signatures.

## Public-key Encryption (ECDH)

![Zencode to encrypt using asymmetric keypairs](img/ecdh_crypt.svg)

In this basic example, the session key for encryption is made by combining
the private key of Alice and the public key of Bob (or
viceversa).

Reusing keys is not really considered secure. However, by combining the
first symmetric key example and this one, it is possible to generate a
random password. The random password is used to encrypt the message and the session key is used
to encrypt the password.

There is also the possibility to add an authenticated clear text
header to the message, using an additional line of Zencode:

```cucumber
When I write 'my secret for you' in 'message'
and I write 'an authenticated message' in 'header'
```

The decryption will always check that the header hasn't changed,
maintaining the integrity of the string which may contain important
public information that accompany the secret.

## Public-key Signature (ECDSA)

![Zencode to sign using asymmetric keypairs](img/ecdsa_sign.svg)

In this example Alice uses her private key to sign and authenticate a
message. Bob, or anyone else, can use Alice's public key to prove that
the integrity of the message is kept intact and that she signed it.

# Memory model

By now it should be clear that a Zencode contract operates on data in 3 phases: 1: **Given** -> 2: **When** -> 3: **Then**

1. reads an input
2. processes its contents
3. prints out the results

The 3 separate blocks of code also correspond to 3 memory areas.

![Zencode documentation diagram](img/zencode_diagram.png)

# List of statements

```yaml
data:
  - {then: 'print '''' '''''}
  - {then: 'print all data'}
  - {then: 'print my data'}
  - {then: 'print my '''''}
  - {then: 'print my draft'}
  - {then: 'print as '''' my draft'}
  - {then: 'print my draft as '''''}
  - {then: 'print as '''' my '''''}
  - {then: 'print the '''''}
  - {then: 'print as '''' the '''''}
  - {then: 'print as '''' the '''' inside '''''}
  - {then: debug}
basic:
  - {when: 'I create my new keypair'}
  - {when: 'I generate my keys'}
  - {when: 'I encrypt the '''' to '''' for '''''}
  - {when: 'I decrypt the '''' to '''''}
  - {when: 'I sign the draft as '''''}
  - {when: 'I verify the '''' is authentic'}
coconut:
  - {when: 'I create my new credential keypair'}
  - {when: 'I create my new credential request keypair'}
  - {when: 'I create my new keypair'}
  - {when: 'I create my new issuer keypair'}
  - {when: 'I create my new authority keypair'}
  - {when: 'I generate a credential signature request'}
  - {when: 'I sign the credential'}
  - {when: 'I aggregate the credential in '''''}
  - {when: 'I aggregate verifiers from '''''}
  - {when: 'I generate a credential proof'}
  - {when: 'I verify the credential proof is correct'}
  - {when: 'I generate a petition '''''}
  - {when: 'I verify the new petition to be empty'}
  - {when: 'I sign the petition '''''}
  - {when: 'I verify the signature proof is correct'}
  - {when: 'the petition signature is not a duplicate'}
  - {when: 'the petition signature is just one more'}
  - {when: 'I add the signature to the petition'}
  - {when: 'I tally the petition'}
  - {when: 'I count the petition results'}
```
