# Shell script examples

This page lists various examples ready to cut and paste into a
terminal where Zenroom is installed, to test running it and examine
the files created.

To run them make sure the `zenroom` executable is in your _$PATH_ or
insert an alias at the beginning of each script like:

```bash
alias zenroom="./src/zenroom"
```

# Credential flow

This script demonstrates the flow of [Attribute Based Credentials](/pages/zencode?id=centralized-credential-issuance)

## Setup

Cut, paste and run in a terminal the script below:

<style>
  .markdown-section pre { margin: 0 }
  .markdown-section pre>code { padding-top: 10px; padding-bottom: 10px }
</style>

```bash
#!/bin/sh
set -e
#
cat << EOF | zenroom -z                                                  >  credential_keypair.json
```
[](../_media/examples/zencode_coconut/credential_keygen.zen ':include :type=code gherkin')
```bash
EOF

cat << EOF | zenroom -z                                                  >  issuer_keypair.json
```
[](../_media/examples/zencode_coconut/issuer_keygen.zen ':include :type=code gherkin')
```bash
EOF

cat << EOF | zenroom -z   -k issuer_keypair.json                         >  verifier.json
```
[](../_media/examples/zencode_coconut/publish_verifier.zen ':include :type=code gherkin')
```bash
EOF

cat << EOF | zenroom -z   -k credential_keypair.json                     >  request.json
```
[](../_media/examples/zencode_coconut/create_request.zen ':include :type=code gherkin')
```bash
EOF

cat << EOF | zenroom -z   -k issuer_keypair.json      -a request.json    >  signature.json
```
[](../_media/examples/zencode_coconut/issuer_sign.zen ':include :type=code gherkin')
```bash
EOF

cat << EOF | zenroom -z   -k credential_keypair.json  -a signature.json  >  credential.json
```
[](../_media/examples/zencode_coconut/aggregate_signature.zen ':include :type=code gherkin')
```bash
EOF
```

Now examine the .json files created at your fingertips.



