load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_ecdh

@test "Encrypt a JSON with a public key" {
    cat << EOF | save_asset scenarioECDHJSONdata.json
{"GoogleMapsMarkers":[{"name":"Rixos The Palm Dubai","position":[25.1212,55.1535]},{"name":"Shangri-La Hotel","location":[25.2084,55.2719]},{"name":"Grand Hyatt","location":[25.2285,55.3273]}],"Geolocation":{"as":"AS16509 Amazon.com, Inc.","city":"Boardman","country":"United States","countryCode":"US","isp":"Amazon","lat":45.8696,"lon":-119.688,"org":"Amazon","query":"54.148.84.95","region":"OR","regionName":"Oregon","status":"success","timezone":"America\/Los_Angeles","zip":"97818"},"twitter":{"created_at":"Thu Jun 22 21:00:00 +0000 2017","id":877994604561387500,"id_str":"877994604561387520","text":"Creating a Grocery List Manager Using Angular, Part 1: Add &amp; Display Items https://t.co/xFox78juL1 #Angular","truncated":false,"entities":{"hashtags":[{"text":"Angular","indices":[103,111]}],"symbols":[],"user_mentions":[],"urls":[{"url":"https://t.co/xFox78juL1","expanded_url":"http://buff.ly/2sr60pf","display_url":"buff.ly/2sr60pf","indices":[79,102]}]},"source":"<a href=\"http://bufferapp.com\" rel=\"nofollow\">Buffer</a>","user":{"id":772682964,"id_str":"772682964","name":"SitePoint JavaScript","screen_name":"SitePointJS","location":"Melbourne, Australia","description":"Keep up with JavaScript tutorials, tips, tricks and articles at SitePoint.","url":"http://t.co/cCH13gqeUK","entities":{"url":{"urls":[{"url":"http://t.co/cCH13gqeUK","expanded_url":"https://www.sitepoint.com/javascript","display_url":"sitepoint.com/javascript","indices":[0,22]}]},"description":{"urls":[]}},"protected":false,"followers_count":2145,"friends_count":18,"listed_count":328,"created_at":"Wed Aug 22 02:06:33 +0000 2012","favourites_count":57,"utc_offset":43200,"time_zone":"Wellington"}}}
EOF

    if [[ "`uname -s`" == "Darwin" ]]; then
        cmd_base64="base64 -b 0"
    else
        cmd_base64="base64 -w 0"
    fi

    cat << EOF | $cmd_base64 | save_asset scenarioECDHJSONToBased64.b64
{"GoogleMapsMarkers":[{"name":"Rixos The Palm Dubai","position":[25.1212,55.1535]},{"name":"Shangri-La Hotel","location":[25.2084,55.2719]},{"name":"Grand Hyatt","location":[25.2285,55.3273]}],"Geolocation":{"as":"AS16509 Amazon.com, Inc.","city":"Boardman","country":"United States","countryCode":"US","isp":"Amazon","lat":45.8696,"lon":-119.688,"org":"Amazon","query":"54.148.84.95","region":"OR","regionName":"Oregon","status":"success","timezone":"America\/Los_Angeles","zip":"97818"},"twitter":{"created_at":"Thu Jun 22 21:00:00 +0000 2017","id":877994604561387500,"id_str":"877994604561387520","text":"Creating a Grocery List Manager Using Angular, Part 1: Add &amp; Display Items https://t.co/xFox78juL1 #Angular","truncated":false,"entities":{"hashtags":[{"text":"Angular","indices":[103,111]}],"symbols":[],"user_mentions":[],"urls":[{"url":"https://t.co/xFox78juL1","expanded_url":"http://buff.ly/2sr60pf","display_url":"buff.ly/2sr60pf","indices":[79,102]}]},"source":"<a href=\"http://bufferapp.com\" rel=\"nofollow\">Buffer</a>","user":{"id":772682964,"id_str":"772682964","name":"SitePoint JavaScript","screen_name":"SitePointJS","location":"Melbourne, Australia","description":"Keep up with JavaScript tutorials, tips, tricks and articles at SitePoint.","url":"http://t.co/cCH13gqeUK","entities":{"url":{"urls":[{"url":"http://t.co/cCH13gqeUK","expanded_url":"https://www.sitepoint.com/javascript","display_url":"sitepoint.com/javascript","indices":[0,22]}]},"description":{"urls":[]}},"protected":false,"followers_count":2145,"friends_count":18,"listed_count":328,"created_at":"Wed Aug 22 02:06:33 +0000 2012","favourites_count":57,"utc_offset":43200,"time_zone":"Wellington"}}}
EOF
    cat << EOF | save_asset scenarioECDHJSONInBase64.json
{"jsonFileInBase64" : "$(cat $BATS_SUITE_TMPDIR/scenarioECDHJSONToBased64.b64)"}
EOF
    cat <<EOF | save_asset scenarioECDHJSONAliceBobCarlKeys.json
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
	"myUserName":"Alice"
}
EOF
    cat <<EOF | zexe scenarioECDHJSONEncrypt.zen scenarioECDHJSONInBase64.json scenarioECDHJSONAliceBobCarlKeys.json
Scenario 'ecdh': Alice encrypts a message for Bob and Carl 

# Here we load keypair and public keys
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'
Given that I have a 'public key' from 'Bob'
Given that I have a 'public key' from 'Carl'

# This is something new: here we are loading the payload to be encrypted,
# stating that it's encoded in base64
Given that I have a 'base64' named 'jsonFileInBase64'

# Here we encrypt and rename, as we did when encrypting the regular text message
When I encrypt the secret message of 'jsonFileInBase64' for 'Bob'
When I rename the 'secret message' to 'secretForBob'
When I encrypt the secret message of 'jsonFileInBase64' for 'Carl'
When I rename the 'secret message' to 'secretForCarl'

# and to finish, here we print out the encrypted payloads, for both the recipients
Then print the 'secretForBob' as 'base64'
Then print the 'secretForCarl' as 'base64' 
EOF
    save_output scenarioECDHJSONOutputbase64.json
}

@test "Decrypt a JSON with a public key" {
    cat <<EOF | save_asset scenarioECDHJSONAliceBobDecryptKeys.json
{
	"Bob": {
		"keyring": {
			"ecdh": "psBF05iHz/X8WBpwitJoSsZ7BiKawrdaVfQN3AtTa6I="
		}
	},
	"public_keys": { "Alice": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4=" },
	"myUserName":"Bob"
}
EOF
    cat <<EOF | zexe scenarioECDHJSONDecrypt.zen scenarioECDHJSONOutputbase64.json scenarioECDHJSONAliceBobDecryptKeys.json
Scenario 'ecdh': Bob decrypts the message from Alice 
Given my name is in a 'string' named 'myUserName'
Given I have my 'keyring' 
Given I have a 'public key' named 'Alice' in 'public keys'
Given I have a 'secret message' named 'secretForBob' 
When I decrypt the text of 'secretForBob' from 'Alice'
When I rename the 'text' to 'DecryptedtextForBobBase64'
Then print the 'DecryptedtextForBobBase64' as 'base64'
# The header is here the "DefaultHeader" so we won't print
# Then print the 'header' from 'secretForBob' as 'string'
EOF
    save_output scenarioECDHJSONOutput.json
    cat $BATS_SUITE_TMPDIR/scenarioECDHJSONOutput.json \
	| jq -r '.DecryptedtextForBobBase64' \
	| base64 -d \
	| save_asset scenarioECDHJSONdecryptedOutput.json
}
