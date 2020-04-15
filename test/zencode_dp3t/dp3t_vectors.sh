#!/usr/bin/env bash

# https://github.com/DP-3T/documents

# use built executable
Z=./src/zenroom
D=./test/zencode_dp3t
echo "Zenroom executable: $Z"
echo "destination dir: $D"

cat <<EOF | $Z 2>/dev/null > $D/sk_zero.json
SK = O.new(32):zero()
print( JSON.encode({secret_day_key = SK:hex()}) )
EOF

cat <<EOF | $Z -z -a $D/sk_zero.json 2>/dev/null > $D/sk_next.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a valid 'secret day key'
When I renew the secret day key to a new day
Then print the 'secret day key'
EOF



cat <<EOF | $Z -z -k $D/sk_zero.json 2>/dev/null > $D/ephid_zero.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a valid 'secret day key'
When I set 'epoch' to '15' base '10'
and I set 'broadcast key' to 'Broadcast key' as 'string'
and I create the ephemeral ids for today
Then print the 'ephemeral ids'
EOF


cat <<EOF | $Z -a $D/sk_next.json -k $D/ephid_zero.json 2>/dev/null
SK = JSON.decode(DATA)
print("SK: ".. O.new(32):zero():hex())
print("SK derivation:")
print(SK.secret_day_key)
print''
print("EphIDs derivation (not randomized)")
for k,v in ipairs(JSON.decode(KEYS).ephemeral_ids) do
	print(O.from_number(k-1):hex() .. " " .. v)
end
EOF

cat <<EOF | $Z -z -k $D/sk_zero.json 2>/dev/null > $D/ephid_zero.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a valid 'secret day key'
When I set 'epoch' to '15' base '10'
and I set 'broadcast key' to 'EFBBBF42726f616463617374206b6579' as 'hex'
and I create the ephemeral ids for today
Then print the 'ephemeral ids'
EOF

echo
cat <<EOF | $Z -a $D/sk_next.json -k $D/ephid_zero.json 2>/dev/null
SK = JSON.decode(DATA)
print("BOM prefixed Broadcast key: EFBBBF42726f616463617374206b6579")
print("EphIDs derivation (not randomized)")
for k,v in ipairs(JSON.decode(KEYS).ephemeral_ids) do
	print(O.from_number(k-1):hex() .. " " .. v)
end
EOF

cat <<EOF | $Z | tee $D/sk_zero.json
SK = O.new(32):zero()
SHA256 = HASH.new('sha256')
BROADCAST_KEY = O.from_string("Decentralized Privacy-Preserving Proximity Tracing")
PRF = SHA256:hmac(SK, BROADCAST_KEY)
print( JSON.encode(
	   {broadcast_key = BROADCAST_KEY:hex(), secret_day_key = SK:hex(), PRF = PRF:hex()}) )
SK = O.from_hex('603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4')
PRF = SHA256:hmac(SK, BROADCAST_KEY)
print( JSON.encode(
	   {broadcast_key = BROADCAST_KEY:hex(), secret_day_key = SK:hex(), PRF = PRF:hex()}) )
EOF

