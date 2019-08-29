# Write smart contracts in human language

Zenroom is software inspired by the [language-theoretical
security](http://langsec.org) research and it allows to express
cryptographic operations in a readable domain-specific language called
**Zencode**.

For an explanation of the innovation brought by Zencode see this blog post: [Smart contracts for the English speaker](https://decodeproject.eu/blog/smart-contracts-english-speaker).

A Zencode contract operates on data in 3 phases: 1: Given -> 2: When -> 3: Then

1. reads an input
2. processes its contents
3. prints out the results

The 3 separate blocks of code also correspond to 3 memory areas.

![Zencode documentation diagram](img/zencode_diagram.png)

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
