#!/usr/bin/env bash

# DEBUG=1
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"

cat <<EOF | zexe copy_random.zen
Given nothing

When I create the random 'random'
When I copy 'random' to 'dest'

Then print 'random'
Then print 'dest'
EOF
cat <<EOF >copy_data.json
{ "my_hex": "0011FFFF" }
EOF
cat <<EOF | zexe copy_data.zen -a copy_data.json
Given I have a 'hex' named 'my hex'

When I copy 'my hex' to 'dest'

Then print 'my hex'
Then print 'dest'
EOF

cat <<EOF | save when stringnum.json
{
	"api": "http://3.68.108.18/api/v1/blocks/latest",
	"path": "blocks/",
	"latest": {
		"result": {
			"height": 102
		}
	}

}
EOF

cat <<EOF | zexe append_number_try.zen -a stringnum.json
Given I have a 'string dictionary' named 'latest'

and I have a 'string' named 'path'

When I pickup from path 'latest.result.height'
and I append 'height' to 'path'

Then print the 'path'
EOF

cat <<EOF | save when string-mpack.json
{
"newblock": {
	"newblock-mpack": "haZudW1iZXLHAAAACk1IZ3hNV0psTnepdGltZXN0YW1wxwAAAA5NSGcyTWpkaVlUa3dPQapwYXJlbnRIYXNoxwAAAFhNSGd6TUdJell6YzBOR0k0WkRsaVlqTXdZak00TURRMllXWTFPRGhpWVRsbFpEWTRaamRsTjJaalpEa3pOV0U0WXpRNE5UWmlPR0ZoWXpBek5HVTBOak5opGhhc2jHAAAAWE1IZzVZekF3WW1ZeU9ESmpObVk1WTJGaE1XRTVaamM0Tmpaak1UaGxNbVpsWkRneVpUWTVNREkzTlRWaE16a3hNMlkxT0RKbFpXSXhaV1psT0dZM05EbGqqYmxvY2tjaGFpboSkdHlwZccAAAALWlhSb1pYSmxkVzCkaHR0cMcAAAAgYUhSMGNEb3ZMemM0TGpRM0xqTTRMakl5TXpvNE5UUTGid3PHAAAAHmQzTTZMeTgzT0M0ME55NHpPQzR5TWpNNk9EVTBOZ6RuYW1lxwAAAAtabUZpWTJoaGFXNA==",
	"txid": "dd445fed8ab124ab0c38720db060b730ddcf4c3fe71b3668eacf9505cd17da8f"
	},
	"version": "2.0",
	"id": "20cfe258df01bf6c634b6b79329b20ef7f5bdf69e6c319b06adb44ac9a4b6c67"
}
EOF

cat <<EOF | zexe base64-string-cast.zen -a string-mpack.json
Given I have a 'string dictionary' named 'newblock'
When I pickup from path 'newblock.newblock-mpack'
When I create the 'base64' cast of strings in 'newblock-mpack'
and I create the 'contents' decoded from mpack 'base64'
Then print the 'contents' as 'string'
EOF
