# Shell script examples

This page lists various examples ready to cut and paste into a
terminal where Zenroom is installed, to test running it and examine
the files created.

To run them make sure the "zenroom" executable is in your $PATH or
insert an alias at the beginning of each script like:

```
alias zenroom="./src/zenroom"
```

# Credential flow

This script demonstrates the flow of [Attribute Based Credentials](/zencode/#attribute-based-credentials)

## Setup

Cut, paste and run in a terminal the script below:

```sh
#!/bin/sh
set -e
#
cat << EOF | zenroom -z                                                  >  credential_keypair.json
{! examples/credential_keygen.zen !}
EOF
cat << EOF | zenroom -z                                                  >  issuer_keypair.json
{! examples/issuer_keygen.zen !}
EOF
cat << EOF | zenroom -z   -k issuer_keypair.json                         >  verifier.json
{! examples/publish_verifier.zen !}
EOF
cat << EOF | zenroom -z   -k credential_keypair.json                     >  request.json
{! examples/create_request.zen !}
EOF
cat << EOF | zenroom -z   -k issuer_keypair.json      -a request.json    >  signature.json
{! examples/issuer_sign.zen !}
EOF
cat << EOF | zenroom -z   -k credential_keypair.json  -a signature.json  >  credential.json
{! examples/aggregate_signature.zen !}
EOF
```

Now examine the .json files created at your fingertips.



