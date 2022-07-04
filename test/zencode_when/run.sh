#!/usr/bin/env bash

# DEBUG=1
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"

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

cat <<EOF | save when graphql.json
{"graphql":"bXV0YXRpb24gewogIGNyZWF0ZUVjb25vbWljRXZlbnQoCiAgICBldmVudDogewogICAgICBhY3Rpb246ICJwcm9kdWNlIgogICAgICBwcm92aWRlcjogIjAxRldOMTJYWDdUSlgxQUZGNUtBNFdQTk45IiAjIGJvYgogICAgICByZWNlaXZlcjogIjAxRldOMTJYWDdUSlgxQUZGNUtBNFdQTk45IiAjIGJvYgogICAgICBvdXRwdXRPZjogIjAxRldOMTM2U1BETUtXV0YyM1NXUVpSTTVGIiAjIGhhcnZlc3RpbmcgYXBwbGVzIHByb2Nlc3MKICAgICAgcmVzb3VyY2VDb25mb3Jtc1RvOiAiMDFGV04xMzZZNFpaN0s5RjMxNEhRN01LUkciICMgYXBwbGUKICAgICAgcmVzb3VyY2VRdWFudGl0eTogewogICAgICAgIGhhc051bWVyaWNhbFZhbHVlOiA1MAogICAgICAgIGhhc1VuaXQ6ICIwMUZXTjEzNlM1VlBDQ1IzQjNUR1lEWUVZOSIgIyBraWxvZ3JhbQogICAgICB9CiAgICAgIGF0TG9jYXRpb246ICIwMUZXTjEzNlpBUFE1RU5CRjNGWjc5OTM1RCIgIyBib2IncyBmYXJtCiAgICAgIGhhc1BvaW50SW5UaW1lOiAiMjAyMi0wMS0wMlQwMzowNDowNVoiCiAgICB9CiAgICBuZXdJbnZlbnRvcmllZFJlc291cmNlOiB7CiAgICAgIG5hbWU6ICJib2IncyBhcHBsZXMiCiAgICAgIG5vdGU6ICJib2IncyBkZWxpc2ggYXBwbGVzIgogICAgICB0cmFja2luZ0lkZW50aWZpZXI6ICJsb3QgMTIzIgogICAgICBjdXJyZW50TG9jYXRpb246ICIwMUZXTjEzNlpBUFE1RU5CRjNGWjc5OTM1RCIgIyBib2IncyBmYXJtCiAgICAgIHN0YWdlOiAiMDFGV04xMzZYMTgzRE00M0NUV1hFU05XQUIiICMgZnJlc2gKICAgIH0KICApIHsKICAgIGVjb25vbWljRXZlbnQgewogICAgICBpZAogICAgICBhY3Rpb24ge2lkfQogICAgICBwcm92aWRlciB7aWR9CiAgICAgIHJlY2VpdmVyIHtpZH0KICAgICAgb3V0cHV0T2Yge2lkfQogICAgICByZXNvdXJjZUNvbmZvcm1zVG8ge2lkfQogICAgICByZXNvdXJjZVF1YW50aXR5IHsKICAgICAgICBoYXNOdW1lcmljYWxWYWx1ZQogICAgICAgIGhhc1VuaXQge2lkfQogICAgICB9CiAgICAgIGF0TG9jYXRpb24ge2lkfQogICAgICBoYXNQb2ludEluVGltZQogICAgfQogICAgZWNvbm9taWNSZXNvdXJjZSB7ICMgdGhpcyBpcyB0aGUgbmV3bHktY3JlYXRlZCByZXNvdXJjZQogICAgICBpZAogICAgICBuYW1lCiAgICAgIG5vdGUKICAgICAgdHJhY2tpbmdJZGVudGlmaWVyCiAgICAgIHN0YWdlIHtpZH0KICAgICAgY3VycmVudExvY2F0aW9uIHtpZH0KICAgICAgY29uZm9ybXNUbyB7aWR9CiAgICAgIHByaW1hcnlBY2NvdW50YWJsZSB7aWR9CiAgICAgIGN1c3RvZGlhbiB7aWR9CiAgICAgIGFjY291bnRpbmdRdWFudGl0eSB7CiAgICAgICAgaGFzTnVtZXJpY2FsVmFsdWUKICAgICAgICBoYXNVbml0IHtpZH0KICAgICAgfQogICAgICBvbmhhbmRRdWFudGl0eSB7CiAgICAgICAgaGFzTnVtZXJpY2FsVmFsdWUKICAgICAgICBoYXNVbml0IHtpZH0KICAgICAgfQogICAgfQogIH0KfQo=","schnorr_signature":"CL7LFfLAIgE7e3U2KroR8q18EZ3KMCxaXpwE7MH+ZIpvIhAxIHrO9eZhRO6LQ9GAEtwdXnW04Q89O1eFo4C2JeFI/11i9rc7MjB3PIdBtUk="}
EOF

cat <<EOF | zexe countchar.zen -a graphql.json
Given I have a 'base64' named 'graphql'
When I create the count of char '{' found in 'graphql'
and I rename 'count' to 'open'
and I create the count of char '}' found in 'graphql'
and I remove 'count'
and I remove 'open'
When I create the count of char '(' found in 'graphql'
and I rename 'count' to 'open'
and I create the count of char ')' found in 'graphql'
and I remove 'count'
and I remove 'open'
When I create the count of char '[' found in 'graphql'
and I rename 'count' to 'open'
and I create the count of char ']' found in 'graphql'
and I verify 'count' is equal to 'open'
Then print the string 'OK'
and print 'graphql' as 'string'
EOF
