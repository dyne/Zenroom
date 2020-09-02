#!/usr/bin/env bash

RNGSEED="rngseed=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

####################
# common script init
# if ! test -r ../utils.sh; then
# 	echo "run executable from its own directory: $0"; exit 1; fi
# . ../utils.sh
# Z="`detect_zenroom_path` `detect_zenroom_conf`"
zexe() {
	out="$1"
	shift 1
	>&2 echo "test: $out"
	tee "$out" | zenroom -z $*
}
####################

## Path: ../../docs/examples/zencode_cookbook/

n=0

tmpData5=`mktemp`
tmpData6=`mktemp`

tmpKeys5=`mktemp`
tmpKeys6=`mktemp`

tmpZencode5=`mktemp`
tmpZencode6=`mktemp`



let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   Encrypt a JSON with a public key: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "

cat << EOF > ../../docs/examples/zencode_cookbook/scenarioECDHJSONdata.json
{"GoogleMapsMarkers":[{"name":"Rixos The Palm Dubai","position":[25.1212,55.1535]},{"name":"Shangri-La Hotel","location":[25.2084,55.2719]},{"name":"Grand Hyatt","location":[25.2285,55.3273]}],"Geolocation":{"as":"AS16509 Amazon.com, Inc.","city":"Boardman","country":"United States","countryCode":"US","isp":"Amazon","lat":45.8696,"lon":-119.688,"org":"Amazon","query":"54.148.84.95","region":"OR","regionName":"Oregon","status":"success","timezone":"America\/Los_Angeles","zip":"97818"},"twitter":{"created_at":"Thu Jun 22 21:00:00 +0000 2017","id":877994604561387500,"id_str":"877994604561387520","text":"Creating a Grocery List Manager Using Angular, Part 1: Add &amp; Display Items https://t.co/xFox78juL1 #Angular","truncated":false,"entities":{"hashtags":[{"text":"Angular","indices":[103,111]}],"symbols":[],"user_mentions":[],"urls":[{"url":"https://t.co/xFox78juL1","expanded_url":"http://buff.ly/2sr60pf","display_url":"buff.ly/2sr60pf","indices":[79,102]}]},"source":"<a href=\"http://bufferapp.com\" rel=\"nofollow\">Buffer</a>","user":{"id":772682964,"id_str":"772682964","name":"SitePoint JavaScript","screen_name":"SitePointJS","location":"Melbourne, Australia","description":"Keep up with JavaScript tutorials, tips, tricks and articles at SitePoint.","url":"http://t.co/cCH13gqeUK","entities":{"url":{"urls":[{"url":"http://t.co/cCH13gqeUK","expanded_url":"https://www.sitepoint.com/javascript","display_url":"sitepoint.com/javascript","indices":[0,22]}]},"description":{"urls":[]}},"protected":false,"followers_count":2145,"friends_count":18,"listed_count":328,"created_at":"Wed Aug 22 02:06:33 +0000 2012","favourites_count":57,"utc_offset":43200,"time_zone":"Wellington"}}}
EOF


cat << EOF | base64 -w 0 > ../../docs/examples/zencode_cookbook/scenarioECDHJSONToBased64.b64
{"GoogleMapsMarkers":[{"name":"Rixos The Palm Dubai","position":[25.1212,55.1535]},{"name":"Shangri-La Hotel","location":[25.2084,55.2719]},{"name":"Grand Hyatt","location":[25.2285,55.3273]}],"Geolocation":{"as":"AS16509 Amazon.com, Inc.","city":"Boardman","country":"United States","countryCode":"US","isp":"Amazon","lat":45.8696,"lon":-119.688,"org":"Amazon","query":"54.148.84.95","region":"OR","regionName":"Oregon","status":"success","timezone":"America\/Los_Angeles","zip":"97818"},"twitter":{"created_at":"Thu Jun 22 21:00:00 +0000 2017","id":877994604561387500,"id_str":"877994604561387520","text":"Creating a Grocery List Manager Using Angular, Part 1: Add &amp; Display Items https://t.co/xFox78juL1 #Angular","truncated":false,"entities":{"hashtags":[{"text":"Angular","indices":[103,111]}],"symbols":[],"user_mentions":[],"urls":[{"url":"https://t.co/xFox78juL1","expanded_url":"http://buff.ly/2sr60pf","display_url":"buff.ly/2sr60pf","indices":[79,102]}]},"source":"<a href=\"http://bufferapp.com\" rel=\"nofollow\">Buffer</a>","user":{"id":772682964,"id_str":"772682964","name":"SitePoint JavaScript","screen_name":"SitePointJS","location":"Melbourne, Australia","description":"Keep up with JavaScript tutorials, tips, tricks and articles at SitePoint.","url":"http://t.co/cCH13gqeUK","entities":{"url":{"urls":[{"url":"http://t.co/cCH13gqeUK","expanded_url":"https://www.sitepoint.com/javascript","display_url":"sitepoint.com/javascript","indices":[0,22]}]},"description":{"urls":[]}},"protected":false,"followers_count":2145,"friends_count":18,"listed_count":328,"created_at":"Wed Aug 22 02:06:33 +0000 2012","favourites_count":57,"utc_offset":43200,"time_zone":"Wellington"}}}
EOF

cat << EOF > ../../docs/examples/zencode_cookbook/scenarioECDHJSONInBase64.json
{"jsonFileInBase64" : "$(cat ../../docs/examples/zencode_cookbook/scenarioECDHJSONToBased64.b64)",
"header": "Sample JSON, to be encrypted for Bob and Carl"}
EOF

cat <<EOF  > $tmpData5
{
	"Alice": {
		"keypair": {
			"private_key": "WBdsWLDno9/DNaap8cOXyQsCG182NJ0ddjLo/k05mgs=",
			"public_key": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
		}
	},
	"Bob": {
		"public_key": "BBA0kD35T9lUHR/WhDwBmgg/vMzlu1Vb0qtBjBZ8rbhdtW3AcX6z64a59RqF6FCV5q3lpiFNTmOgA264x1cZHE0="
	},
	"Carl": {
		"public_key": "BLdpLbIcpV5oQ3WWKFDmOQ/zZqTo93cT1SId8HNITgDzFeI6Y3FCBTxsKHeyY1GAbHzABsOf1Zo61FRQFLRAsc8="
	}
}
EOF
cat $tmpData5 > ../../docs/examples/zencode_cookbook/scenarioECDHJSONAliceBobCarlKeys.json



cat <<EOF  > $tmpZencode5
Rule check version 1.0.0
Scenario 'ecdh': Alice encrypts a message for Bob and Carl 

# Here we load keypair and public keys
Given that I am known as 'Alice'
Given that I have my 'keypair'
Given that I have a 'public key' from 'Bob'
Given that I have a 'public key' from 'Carl'

# Here we load the header, as a string just like before
Given that I have a 'string' named 'header'

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


cat $tmpZencode5 > ../../docs/examples/zencode_cookbook/scenarioECDHJSONEncrypt.zen


cat $tmpZencode5 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -k $tmpData5 -a ../../docs/examples/zencode_cookbook/scenarioECDHJSONInBase64.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHJSONOutputbase64.json





echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   Decrypt a JSON with a public key: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData6
{
	"Bob": {
		"keypair": {
			"private_key": "psBF05iHz/X8WBpwitJoSsZ7BiKawrdaVfQN3AtTa6I=",
			"public_key": "BBA0kD35T9lUHR/WhDwBmgg/vMzlu1Vb0qtBjBZ8rbhdtW3AcX6z64a59RqF6FCV5q3lpiFNTmOgA264x1cZHE0="
		}
	},
		"Alice": {
		"public_key": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
	}
}
EOF
cat $tmpData6 > ../../docs/examples/zencode_cookbook/scenarioECDHJSONAliceBobDecryptKeys.json



cat <<EOF  > $tmpZencode6
Rule check version 1.0.0 
Scenario 'ecdh': Bob decrypts the message from Alice 
Given that I am known as 'Bob' 
Given I have my 'keypair' 
Given I have a 'public key' from 'Alice' 
Given I have a 'secret message' named 'secretForBob' 
When I decrypt the text of 'secretForBob' from 'Alice'
When I rename the 'text' to 'textForBob'
Then print the 'textForBob' as 'base64' 
Then print the 'header' as 'string' inside 'secretForBob' 
EOF


cat $tmpZencode6 > ../../docs/examples/zencode_cookbook/scenarioECDHJSONDecrypt.zen

cat $tmpZencode6 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -k $tmpData6 -a ../../docs/examples/zencode_cookbook/scenarioECDHJSONOutputbase64.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHJSONOutput.json


cat ../../docs/examples/zencode_cookbook/scenarioECDHJSONOutput.json | jq -r '.textForBob' | base64 -d | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHJSONdecryptedOutput.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "




rm -f ../../docs/examples/zencode_cookbook/temp.zen

rm -f $tmp

rm -f $tmpData5
rm -f $tmpData6

rm -f $tmpKeys5
rm -f $tmpKeys6

rm -f $tmpZencode5
rm -f $tmpZencode6
