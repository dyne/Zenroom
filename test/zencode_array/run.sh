#!/usr/bin/env bash

DEBUG=1
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

set -e

cat <<EOF | zexe array_32_256.zen | save array arr.json
rule output encoding url64
Given nothing
When I create the array of '32' random objects of '256' bits
and I rename the 'array' to 'bonnetjes'
Then print the 'bonnetjes'
EOF

cat << EOF | zexe array_length.zen -a arr.json
Given I have a 'url64 array' named 'bonnetjes'
When I create the length of 'bonnetjes'
Then print the 'length'
EOF

cat <<EOF | zexe array_rename_remove.zen -a arr.json
rule input encoding url64
rule output encoding hex
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I rename the 'random object' to 'lucky one'
and I remove the 'lucky one' from 'bonnetjes'
# redundant check
and the 'lucky one' is not found in 'bonnetjes'
Then print the 'lucky one'
EOF

# cat <<EOF | zexe array_hashtopoint.zen -a arr.json > ecp.json
# rule input encoding url64
# rule output encoding url64
# Given I have a 'array' named 'bonnetjes'
# When I create the hash to point 'ECP' of each object in 'bonnetjes'
# # When for each x in 'bonnetjes' create the of 'ECP.hashtopoint(x)'
# Then print the 'hashes'
# EOF

# cat <<EOF | zexe array_ecp_check.zen -a arr.json -k ecp.json > hashes.json
# rule input encoding url64
# rule output encoding url64
# Given I have a 'array' named 'bonnetjes'
# and I have a 'ecp array' named 'hashes'
# # When I pick the random object in array 'hashes'
# # and I remove the 'random object' from array 'hashes'
# When for each x in 'hashes' y in 'bonnetjes' is true 'x == ECP.hashtopoint(y)'
# Then print the 'hashes'
# EOF
# # 'x == ECP.hashtopoint(y)'


cat <<EOF | zexe left_array_from_hash.zen -a arr.json > left_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'left array'
Then print the 'left array'
EOF


cat <<EOF | zexe right_array_from_hash.zen -a arr.json > right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'right array'
Then print the 'right array'
EOF

# comparison

cat <<EOF | zexe array_comparison.zen -a left_arr.json -k right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'left array'
and I have a 'url64 array' named 'right array'
When I verify 'left array' is equal to 'right array'
Then print the string 'OK'
EOF

cat <<EOF | zexe array_remove_object.zen -a arr.json > right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I remove the 'random object' from 'bonnetjes'
and I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'right array'
Then print the 'right array'
EOF

# verify that arrays are not equal
cat <<EOF | zexe array_not_comparison.zen -a left_arr.json -k right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'left array'
and I have a 'url64 array' named 'right array'
When I verify 'left array' is not equal to 'right array'
Then print the string 'OK'
EOF


# 'x == ECP.hashtopoint(y)'

cat <<EOF > nesting.json
{
  "first" : { "inside" : "first.inside" },
  "second" : { "inside" : "second.inside" },
  "third" : "three"
}
EOF

cat <<EOF | zexe pick_nested.zen -a nesting.json
rule check version 1.0.0
rule input encoding string
Given I have a 'string' named 'inside' inside 'first'
and I have a 'string' named 'third'
When I write string 'first.inside' in 'test'
and I write string 'three' in 'tertiur'
and I verify 'third' is equal to 'tertiur'
Then print the 'test' as 'string'
EOF

cat <<EOF | zexe leftmost_split.zen
rule check version 1.0.0
Given nothing
When I set 'whole' to 'Zenroom works great' as 'string'
and I split the leftmost '3' bytes of 'whole'
Then print the 'leftmost' as 'string'
and print the 'whole' as 'string'
EOF

# cat << EOF > array_public_bls.json
# { "public_keys": {
#  "Alice":{"reflow_public_key": "KrfEl2HFpml3di0N5vnrN+yrbSgiSClGBgz9zEmp2BihHOejIuOrTsOS573Fh6ciCxv6jI3syiF7mfGKUKXurUruj1kUtJfRpXHXa4d22LlioeB9uv+l14qhecrFojboOGrxZulFoDKVVWVCB0/bAD6HquSmvX4+jyPl/BLt6TUnNDLeWK8vm6zu9sR8/XFtKqEfCgQB4u0vbDhqOKhRNut8MjLtMcxYgWZTunmszNAZdAGMcYSod/0p1AzOnAUi"},
#  "Bob"  :{"reflow_public_key": "HA5WkWcTL0bJRRtjaTlW67SxTKBvuMniEOuao+jeuKA/2PT5965hvJgeDuTc2dHjGkCUzTjYhruOmY8puiF6s+8LRttJo17utYtsDNtNPNpaNdDSg8Dsg+wljGnqDUW8Jy29GQtuse2nqCOhGDzx9XC9pRCcu7hxAlIQsivpI2D9vXvi6BrVEniFG/kOrzzaUXXWNzBEuLhkwgvHcjLwC4Ph6ynrcsFIwEZycKuJKCaoOJu/ZQRT/nyfSf/Bom2k"}
# } }
# EOF

# cat <<EOF | debug array_schema.zen -a array_public_bls.json
# Scenario reflow
# Given I have a 'reflow public key array' named 'public keys'
# Then print all data
# EOF

cat << EOF > array_matches.json
{ "haystack": [ "Approved", "Not approved", "Approved", "Not approved", "Approved","Not approved", "Approved","Not approved", "Approved" ] }
EOF
cat << EOF > quorum.json
{ "quorum": 5,
  "needle": "Approved" }
EOF

cat << EOF | zexe needle_in_haystack.zen -a array_matches.json -k quorum.json
Given I have a 'string array' named 'haystack'
and I have a 'number' named 'quorum'
and I have a 'string' named 'needle'
When the 'needle' is found in 'haystack' at least 'quorum' times
Then Print the string 'Success' 
EOF

cat <<EOF >timestamp_stats.json
{
	"1": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://50.116.53.12:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787666",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "c633408f9d364740bec696456d5f1ae2",
		"version": "1"
	},
	"2": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://172.105.83.46:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787611",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "c1da19c60b7a4bf7a66f60825bec7a82",
		"version": "1"
	},
	"3": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://212.71.234.197:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787367",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "cc95dbf6a3d340fb95452f452a23aa40",
		"version": "1"
	},
	"4": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://192.46.209.107:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787754",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "3d0fa08a6d034d01a820ea05cbf93831",
		"version": "1"
	},
	"5": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://172.105.18.196:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787679",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "3794a7c3d1734dc8abcb57c82c972549",
		"version": "1"
	},
	"6": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://45.79.92.158:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787692",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "11e06cf7615a43f08ebd31c97e1ef9cb",
		"version": "1"
	},
        "non numero": "quarantadue"
}
EOF


cat <<EOF | zexe timestamp_stats.zen -a timestamp_stats.json
Given I have a 'string dictionary' named '1'
Given I have a 'string dictionary' named '2'
Given I have a 'string dictionary' named '3'
Given I have a 'string dictionary' named '4'
Given I have a 'string dictionary' named '5'
Given I have a 'string dictionary' named '6'

Given I have the 'string' named 'non numero'

When I create the copy of 'myTimestamp' from dictionary '1'
When I rename the 'copy' to 'time1'

When I create the copy of 'myTimestamp' from dictionary '2'
When I rename the 'copy' to 'time2'

When I create the copy of 'myTimestamp' from dictionary '3'
When I rename the 'copy' to 'time3'

When I create the copy of 'myTimestamp' from dictionary '4'
When I rename the 'copy' to 'time4'

When I create the copy of 'myTimestamp' from dictionary '5'
When I rename the 'copy' to 'time5'

When I create the copy of 'myTimestamp' from dictionary '6'
When I rename the 'copy' to 'time6'

# Insert timestamps in array to create average and variance

When I create the 'string array'
When I rename the 'string array' to 'allTimestamps'

When I insert 'time1' in 'allTimestamps'
When I insert 'time2' in 'allTimestamps'
When I insert 'time3' in 'allTimestamps'
When I insert 'time4' in 'allTimestamps'
When I insert 'time5' in 'allTimestamps'
When I insert 'time6' in 'allTimestamps'
# When I insert 'non numero' in 'allTimestamps'

When I create the average of elements in array 'allTimestamps'
When I create the variance of elements in array 'allTimestamps'
When I create the standard deviation of elements in array 'allTimestamps'

Then print the 'average'
Then print the 'variance'
Then print the 'standard deviation'
Then print the 'allTimestamps'
EOF

cat <<EOF > not_flat_array.json
{
"identities": [
	[
	     	"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	],
	[
		"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	],
	[
		"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	],
	[
		"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	]
]
}
EOF

cat <<EOF | zexe flat_array.zen -a not_flat_array.json | jq .
Rule check version 2.0.0
Given I have a 'string array' named 'identities'
When I create the flat array of contents in 'identities'
and I rename 'flat array' to 'contents flat array'
When I create the flat array of keys in 'identities'
and I rename 'flat array' to 'keys flat array'
Then print the 'keys flat array'
and print the 'contents flat array'
EOF

cat timestamp_stats.json | jq '{"timestamp": . }' > not_flat_dic.json

cat <<EOF | zexe flat_array_contents.zen -a not_flat_dic.json | jq .
Rule check version 2.0.0
Given I have a 'string dictionary' named 'timestamp'
When I create the flat array of contents in 'timestamp'
and I rename 'flat array' to 'contents flat array'
When I create the flat array of keys in 'timestamp'
and I rename 'flat array' to 'keys flat array'
Then print the 'keys flat array'
and print the 'contents flat array'
EOF

cat <<EOF > consensusroom-flatten.data
{
 "identities": [
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ],
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ],
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ],
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ]
 ],
 "identity": {
  "uid": "random",
  "ip": "hostname -I",
  "baseUrl": "http://hostname -I",
  "port_http": "$PORT_HTTP",
  "port_https": "$PORT_HTTPS",
  "public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
  "version": "2",
  "announceAPI": "/api/consensusroom-announce",
  "get-6-timestampsAPI": "/api/consensusroom-get-6-timestamps",
  "timestampAPI": "/api/consensusroom-get-timestamp",
  "tracker": "https://apiroom.net/"
 }
}
EOF

cat <<EOF | zexe consensusroom-flatten.zen -a consensusroom-flatten.data
Given I have a 'string array' named 'identities'
Given I have a 'string dictionary' named 'identity'

When I create the flat array of contents in 'identities'
When I rename the 'flat array' to 'flattened array 1'

When I create the flat array of keys in 'identity'
When I rename the 'flat array' to 'flattened array 2'

Then print the 'flattened array 1'
Then print the 'flattened array 2'
Then print the string 'succes'
EOF


cat <<EOF | save array dictionaries.json
{
	"nameOfObject": "timestampEndpoint",
	"identities": {
		"172.105.105.137": {
			"announce": "/api/consensusroom-announce",
			"baseUrl": "http://172.105.105.137:3300",
			"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timestampAPI": "/api/consensusroom-get-timestamp",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "172.105.105.137",
			"updateAPI": "/api/consensusroom-update",
			"version": "1"
		},
		"172.105.33.141": {
			"announce": "/api/consensusroom-announce",
			"baseUrl": "http://172.105.33.141:3300",
			"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timestampAPI": "/api/consensusroom-get-timestamp",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "172.105.33.141",
			"updateAPI": "/api/consensusroom-update",
			"version": "1"
		},
		"194.195.123.140": {
			"announce": "/api/consensusroom-announce",
			"baseUrl": "http://194.195.123.140:3300",
			"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timestampAPI": "/api/consensusroom-get-timestamp",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "194.195.123.140",
			"updateAPI": "/api/consensusroom-update",
			"version": "1"
		},
		"194.195.240.46": {
			"announce": "/api/consensusroom-announce",
			"baseUrl": "http://194.195.240.46:3300",
			"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timestampAPI": "/api/consensusroom-get-timestamp",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "194.195.240.46",
			"updateAPI": "/api/consensusroom-update",
			"version": "1"
		},
		"45.33.44.32": {
			"announce": "/api/consensusroom-announce",
			"baseUrl": "http://45.33.44.32:3300",
			"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timestampAPI": "/api/consensusroom-get-timestamp",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "45.33.44.32",
			"updateAPI": "/api/consensusroom-update",
			"version": "1"
		},
		"50.116.61.250": {
			"announce": "/api/consensusroom-announce",
			"baseUrl": "http://50.116.61.250:3300",
			"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timestampAPI": "/api/consensusroom-get-timestamp",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "50.116.61.250",
			"updateAPI": "/api/consensusroom-update",
			"version": "1"
		},
		"Pepero": {
			"baseUrl": "http://192.168.0.100:3030",
			"ip": "192.168.0.100",
			"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
			"timeServer": "http://localhost:3312",
			"timestampEndpoint": "http://172.105.105.137:3300/api/consensusroom-get-timestamp",
			"uid": "Kenshiro",
			"version": "1"
		}
	}
}
EOF

cat <<EOF | zexe dict2array.zen -a dictionaries.json
Given I have a 'string dictionary' named 'identities'
and a 'string' named 'nameOfObject'
When I create the array of objects named by 'nameOfObject' found in 'identities'
Then print the 'array'
EOF

cat <<EOF > compare-equal.data
{
 "arr": [1,1,1,1],
 "dict": {
   "hello": "world",
   "nice": "world",
   "big": "world"
 },
 "empty_dict": {},
 "nested_arr": [
   { "nested": "nested" },
   { "nested": "nested" }
 ]

}
EOF

cat <<EOF | zexe compare-equal.zen -a compare-equal.data
Given I have a 'string array' named 'arr'
Given I have a 'string dictionary' named 'dict'
Given I have a 'string array' named 'nested_arr'
Given I have a 'string dictionary' named 'empty_dict'

If the elements in 'arr' are all equal
If the elements in 'dict' are all equal
If the elements in 'nested arr' are all equal
If the elements in 'empty dict' are all equal
Then print string 'OK'
EOF

cat <<EOF > compare-not-equal.data
{
 "arr": [1,1,1,3],
 "dict": {
   "hello": "world",
   "nice": "world",
   "big": "earth"
 },
 "nested_arr": [
   { "nested": "nested" },
   { "nested": "not-nested" }
 ]

}
EOF

cat <<EOF | zexe compare-not-equal.zen -a compare-not-equal.data
Given I have a 'string array' named 'arr'
Given I have a 'string dictionary' named 'dict'
Given I have a 'string array' named 'nested_arr'

If the elements in 'arr' are not all equal
If the elements in 'dict' are not all equal
If the elements in 'nested arr' are not all equal
Then print string 'OK'
EOF

cat <<EOF | save array table-arrays.json
{ "identity": {
    "announceAPI": "/api/zenswarm-oracle-announce",
    "baseUrl": "http://zenswarm.zenroom.org",
    "country": "IT",
    "ethereum-notarizationAPI": "/api/ethereum-to-ethereum-notarization.chain",
    "get-identityAPI": "/api/zenswarm-oracle-get-identity",
    "http-postAPI": "/api/zenswarm-oracle-http-post",
    "oracle-key-issuance": "/api/zenswarm-oracle-key-issuance.chain",
    "pingAPI": "/api/zenswarm-oracle-ping.zen",
    "port_http": "28170",
    "port_https": "28331",
    "sawroom-notarizationAPI": "/api/sawroom-to-ethereum-notarization.chain",
    "timestampAPI": "/api/zenswarm-oracle-get-timestamp.zen",
    "tracker": "https://apiroom.net/",
    "type": "restroom-mw",
    "updateAPI": "/api/zenswarm-oracle-update",
    "version": "2"
  },
"identities": [
 {
      "announceAPI": "/api/zenswarm-oracle-announce",
      "baseUrl": "http://zenswarm.zenroom.org",
      "country": "IT",
      "ethereum-notarizationAPI": "/api/ethereum-to-ethereum-notarization.chain",
      "get-identityAPI": "/api/zenswarm-oracle-get-identity",
      "http-postAPI": "/api/zenswarm-oracle-http-post",
      "oracle-key-issuance": "/api/zenswarm-oracle-key-issuance.chain",
      "pingAPI": "/api/zenswarm-oracle-ping.zen",
      "port_http": "26962",
      "port_https": "25991",
      "region": "NONE",
      "sawroom-notarizationAPI": "/api/sawroom-to-ethereum-notarization.chain",
      "timestampAPI": "/api/zenswarm-oracle-get-timestamp.zen",
      "tracker": "https://apiroom.net/",
      "type": "restroom-mw",
      "updateAPI": "/api/zenswarm-oracle-update",
      "version": "2"
    },
    {
      "announceAPI": "/api/zenswarm-oracle-announce",
      "baseUrl": "http://zenswarm.zenroom.org",
      "country": "IT",
      "ethereum-notarizationAPI": "/api/ethereum-to-ethereum-notarization.chain",
      "get-identityAPI": "/api/zenswarm-oracle-get-identity",
      "http-postAPI": "/api/zenswarm-oracle-http-post",
      "oracle-key-issuance": "/api/zenswarm-oracle-key-issuance.chain",
      "pingAPI": "/api/zenswarm-oracle-ping.zen",
      "port_http": "26368",
      "port_https": "29841",
      "region": "NONE",
      "sawroom-notarizationAPI": "/api/sawroom-to-ethereum-notarization.chain",
      "timestampAPI": "/api/zenswarm-oracle-get-timestamp.zen",
      "tracker": "https://apiroom.net/",
      "type": "restroom-mw",
      "updateAPI": "/api/zenswarm-oracle-update",
      "version": "2"
    },
{
    "announceAPI": "/api/zenswarm-oracle-announce",
    "baseUrl": "http://zenswarm.zenroom.org",
    "country": "IT",
    "ethereum-notarizationAPI": "/api/ethereum-to-ethereum-notarization.chain",
    "get-identityAPI": "/api/zenswarm-oracle-get-identity",
    "http-postAPI": "/api/zenswarm-oracle-http-post",
    "oracle-key-issuance": "/api/zenswarm-oracle-key-issuance.chain",
    "pingAPI": "/api/zenswarm-oracle-ping.zen",
    "port_http": "28170",
    "port_https": "28331",
    "sawroom-notarizationAPI": "/api/sawroom-to-ethereum-notarization.chain",
    "timestampAPI": "/api/zenswarm-oracle-get-timestamp.zen",
    "tracker": "https://apiroom.net/",
    "type": "restroom-mw",
    "updateAPI": "/api/zenswarm-oracle-update",
    "version": "2"
}
  ]
}

EOF

cat <<EOF | zexe remove-table-from-table.zen -a table-arrays.json | jq .
Given I have a 'string array' named 'identities'
Given I have a 'string array' named 'identity'
When I create the size of 'identities'
and I rename 'size' to 'before'
and I remove the 'identity' from 'identities'
and I create the size of 'identities'
and I rename 'size' to 'after'
Then print the 'before'
and print the 'after'
EOF

cat <<EOF > split.data
{
  "id": "did:example:123456789abcdefghi#keys-1",
  "strange_id": "did::",
  "very_strange_id": "::",
  "separator": ":"
}
EOF

cat <<EOF | zexe split.zen -a split.data
Given I have a 'string' named 'id'
Given I have a 'string' named 'strange_id'
Given I have a 'string' named 'very_strange_id'
Given I have a 'string' named 'separator'
When I create the array by splitting 'strange_id' at 'separator'
When I rename 'array' to 'strange_array'
When I create the array by splitting 'very_strange_id' at 'separator'
When I rename 'array' to 'very_strange_array'
When I create the array by splitting 'id' at 'separator'
Then print the data
EOF

success
