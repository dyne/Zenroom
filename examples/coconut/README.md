# Coconut

by Alberto Sonnino, Mustafa Al-Bassam, Shehar Bano, Sarah Meiklejohn, George Danezis

[Link to the full paper (arXiv:1802.07344)](https://arxiv.org/abs/1802.07344)

## Selective Disclosure Credentials with Applications to Distributed Ledgers

Coconut is a cryptographic scheme useful to applications related to
anonymous payments and electronic petitions. It is a novel selective
disclosure credential scheme for Attribute Based Credentials (ABC)
supporting public and private attributes, re-randomization, and
multiple unlinkable selective attribute revelations.

This implementation is written in Zencode and runs inside any Zenroom
VM; it implements all features described in the paper with the
exception of distributed threshold issuance, which will be implemented
at a later stage for use in permissionless blockchains.

Coconut uses short and computationally efficient credentials, and our
evaluation shows that most Coconut cryptographic primitives take just
a few milliseconds on average, with verification taking the longest
time.
