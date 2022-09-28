load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_hash_pdf

@test "hash file and sign the head" {
    if [[ "`uname -s`" == "Darwin" ]]; then
        cmd_base64="base64 -b 0"
    else
        cmd_base64="base64 -w 0"
    fi
    if [[ "`uname -s`" == "Darwin" ]]; then
        cmd_stat_time="stat -f \"%SB\""
    else
        cmd_stat_time="stat -c \"%y\""
    fi
    if [[ "`uname -s`" == "Darwin" ]]; then
        cmd_stat_size="stat -f \"%z\""
    else
        cmd_stat_size="stat -c \"%s\""
    fi
    tmpFile="$R/docs/pages/lua.md"
    cat << EOF | save_asset fileToHash.json
{
"fileToBeHashedBase64" : "$($cmd_base64 $tmpFile)",
	"fileToBeHashed.Metadata" : {
		"nameOfFileToBeHashed" : "$tmpFile",
		"dateOfFileToBeHashed" : $($cmd_stat_time $tmpFile),
		"sizeOfFileToBeHashedinBytes" : $($cmd_stat_size $tmpFile)
	}
}
EOF
    cat <<EOF | save_asset AliceKeyring.json
{
	"Alice": {
		"keyring": {
			"ecdh": "WBdsWLDno9/DNaap8cOXyQsCG182NJ0ddjLo/k05mgs="
		}
	},
	"Bob": {
		"public_key": "BBA0kD35T9lUHR/WhDwBmgg/vMzlu1Vb0qtBjBZ8rbhdtW3AcX6z64a59RqF6FCV5q3lpiFNTmOgA264x1cZHE0="
	},
	"Carl": {
		"public_key": "BLdpLbIcpV5oQ3WWKFDmOQ/zZqTo93cT1SId8HNITgDzFeI6Y3FCBTxsKHeyY1GAbHzABsOf1Zo61FRQFLRAsc8="
	},
	"myUserName":"Alice",
	"myPassword":"myFancyPassword"
}
EOF
    cat <<EOF | zexe HashPdf.zen fileToHash.json AliceKeyring.json
Rule check version 2.0.0
Scenario 'ecdh': Alice encrypts a message for Bob and Carl

# Here we load keyring and public keys
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'
Given that I have a 'string' named 'myPassword'
Given that I have a 'string dictionary' named 'fileToBeHashed.Metadata'


# This is something new: here we are loading the payload to be encrypted,
# stating that it's encoded in base64
Given that I have a 'base64' named 'fileToBeHashedBase64'

# Here we create the simplest hash the file, using the default algorythm "sha256"
When I create the hash of 'fileToBeHashedBase64' using 'sha256'
And I rename the 'hash' to 'sha256HashOffile'

# Here we create the hash the file using sha512
When I create the hash of 'fileToBeHashedBase64' using 'sha512'
And I rename the 'hash' to 'sha512HashOffile'

# Here we create the simplest hash the file (using sha256)
When I create the HMAC of 'fileToBeHashedBase64' with key 'myPassword'
And I rename the 'HMAC' to 'HMACHashOffile'

# Create a dictionary that contains all the hashes
When I create the 'base64 dictionary'
and I rename the 'base64 dictionary' to 'fileToBeHashed.Hashes'

When I insert 'sha256HashOffile' in 'fileToBeHashed.Hashes'
When I insert 'sha512HashOffile' in 'fileToBeHashed.Hashes'



# sign all the hashes
When I create the signature of 'fileToBeHashed.Hashes'
and I rename the 'signature' to 'fileToBeHashed.Hashes.signature'

# sign all the metadata
When I create the signature of 'fileToBeHashed.Metadata'
and I rename the 'signature' to 'fileToBeHashed.Metadata.signature'

When I create the 'base64 dictionary'
and I rename the 'base64 dictionary' to 'fileToBeHashed.signatures'
When I insert 'fileToBeHashed.Hashes.signature' in 'fileToBeHashed.signatures'
When I insert 'fileToBeHashed.Metadata.signature' in 'fileToBeHashed.signatures'

# and to finish, here we print out the encrypted payloads, for both the recipients
# Then print the 'sha256HashOffile'
# Then print the 'sha512HashOffile'
Then print the 'fileToBeHashed.Hashes'
Then print the 'fileToBeHashed.Metadata'
Then print the 'fileToBeHashed.signatures'
EOF
    save_output fileToHashOutput.json
}
