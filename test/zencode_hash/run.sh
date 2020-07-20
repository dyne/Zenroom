#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################


cat << EOF | zexe hash_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF

cat << EOF | zexe kdf_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the key derivation of 'source'
Then print 'key derivation'
EOF

cat << EOF | zexe pbkdf_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my pbkdf password' in 'secret' 
and I create the key derivation of 'source' with password 'secret'
Then print 'key derivation'
EOF

cat << EOF | zexe hmac_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my HMAC key' in 'secret'
and I create the HMAC of 'source' with key 'secret'
Then print 'HMAC'
EOF

cat << EOF | zexe hash_sha512.zen
rule output encoding hex
rule set hash sha512
Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF

