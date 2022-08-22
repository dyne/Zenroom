load ../bats_setup
load ../bats_zencode
SUBDOC=when


@test "When I copy '' to ''" {
cat <<EOF >copy_data.data
{ "my_hex": "0011FFFF" }
EOF
cat <<EOF | zexe copy_data.zen copy_data.data
Given I have a 'hex' named 'my hex'

When I copy 'my hex' to 'dest'

Then print 'my hex'
Then print 'dest'
EOF
    save_output 'copy_data.out'
    assert_output '{"dest":"0011ffff","my_hex":"0011ffff"}'
}

@test "When I pickup from path ''" {
    cat <<EOF | save_asset stringnum.json
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

    cat <<EOF | zexe append_number_try.zen stringnum.json
Given I have a 'string dictionary' named 'latest'

and I have a 'string' named 'path'

When I pickup from path 'latest.result.height'
and I append 'height' to 'path'

Then print the 'path'
EOF
    save_output 'append_number_try.out'
    assert_output '{"path":"blocks/102"}'

}

@test "When I create the '' cast of strings in ''" {
    cat <<EOF | save_asset string-mpack.json
{
"newblock": {
	"newblock-mpack": "haZudW1iZXLHAAAACk1IZ3hNV0psTnepdGltZXN0YW1wxwAAAA5NSGcyTWpkaVlUa3dPQapwYXJlbnRIYXNoxwAAAFhNSGd6TUdJell6YzBOR0k0WkRsaVlqTXdZak00TURRMllXWTFPRGhpWVRsbFpEWTRaamRsTjJaalpEa3pOV0U0WXpRNE5UWmlPR0ZoWXpBek5HVTBOak5opGhhc2jHAAAAWE1IZzVZekF3WW1ZeU9ESmpObVk1WTJGaE1XRTVaamM0Tmpaak1UaGxNbVpsWkRneVpUWTVNREkzTlRWaE16a3hNMlkxT0RKbFpXSXhaV1psT0dZM05EbGqqYmxvY2tjaGFpboSkdHlwZccAAAALWlhSb1pYSmxkVzCkaHR0cMcAAAAgYUhSMGNEb3ZMemM0TGpRM0xqTTRMakl5TXpvNE5UUTGid3PHAAAAHmQzTTZMeTgzT0M0ME55NHpPQzR5TWpNNk9EVTBOZ6RuYW1lxwAAAAtabUZpWTJoaGFXNA==",
	"txid": "dd445fed8ab124ab0c38720db060b730ddcf4c3fe71b3668eacf9505cd17da8f"
	},
	"version": "2.0",
	"id": "20cfe258df01bf6c634b6b79329b20ef7f5bdf69e6c319b06adb44ac9a4b6c67"
}
EOF

    cat <<EOF | zexe base64-string-cast.zen string-mpack.json
Given I have a 'string dictionary' named 'newblock'
When I pickup from path 'newblock.newblock-mpack'
When I create the 'base64' cast of strings in 'newblock-mpack'
and I create the 'contents' decoded from mpack 'base64'
Then print the 'contents' as 'string'
EOF
    save_output 'base64-string-cast.out'
    assert_output '{"contents":{"blockchain":{"http":"http://78.47.38.223:8545","name":"fabchain","type":"ethereum","ws":"ws://78.47.38.223:8546"},"hash":"0x9c00bf282c6f9caa1a9f7866c18e2fed82e6902755a3913f582eeb1efe8f749c","number":"0x11be7","parentHash":"0x30b3c744b8d9bb30b38046af588ba9ed68f7e7fcd935a8c4856b8aac034e463a","timestamp":"0x627ba908"}}'
}

@test "Count chars" {
    cat <<EOF | save_asset graphql.json
{"graphql":"bXV0YXRpb24gewogIGNyZWF0ZUVjb25vbWljRXZlbnQoCiAgICBldmVudDogewogICAgICBhY3Rpb246ICJwcm9kdWNlIgogICAgICBwcm92aWRlcjogIjAxRldOMTJYWDdUSlgxQUZGNUtBNFdQTk45IiAjIGJvYgogICAgICByZWNlaXZlcjogIjAxRldOMTJYWDdUSlgxQUZGNUtBNFdQTk45IiAjIGJvYgogICAgICBvdXRwdXRPZjogIjAxRldOMTM2U1BETUtXV0YyM1NXUVpSTTVGIiAjIGhhcnZlc3RpbmcgYXBwbGVzIHByb2Nlc3MKICAgICAgcmVzb3VyY2VDb25mb3Jtc1RvOiAiMDFGV04xMzZZNFpaN0s5RjMxNEhRN01LUkciICMgYXBwbGUKICAgICAgcmVzb3VyY2VRdWFudGl0eTogewogICAgICAgIGhhc051bWVyaWNhbFZhbHVlOiA1MAogICAgICAgIGhhc1VuaXQ6ICIwMUZXTjEzNlM1VlBDQ1IzQjNUR1lEWUVZOSIgIyBraWxvZ3JhbQogICAgICB9CiAgICAgIGF0TG9jYXRpb246ICIwMUZXTjEzNlpBUFE1RU5CRjNGWjc5OTM1RCIgIyBib2IncyBmYXJtCiAgICAgIGhhc1BvaW50SW5UaW1lOiAiMjAyMi0wMS0wMlQwMzowNDowNVoiCiAgICB9CiAgICBuZXdJbnZlbnRvcmllZFJlc291cmNlOiB7CiAgICAgIG5hbWU6ICJib2IncyBhcHBsZXMiCiAgICAgIG5vdGU6ICJib2IncyBkZWxpc2ggYXBwbGVzIgogICAgICB0cmFja2luZ0lkZW50aWZpZXI6ICJsb3QgMTIzIgogICAgICBjdXJyZW50TG9jYXRpb246ICIwMUZXTjEzNlpBUFE1RU5CRjNGWjc5OTM1RCIgIyBib2IncyBmYXJtCiAgICAgIHN0YWdlOiAiMDFGV04xMzZYMTgzRE00M0NUV1hFU05XQUIiICMgZnJlc2gKICAgIH0KICApIHsKICAgIGVjb25vbWljRXZlbnQgewogICAgICBpZAogICAgICBhY3Rpb24ge2lkfQogICAgICBwcm92aWRlciB7aWR9CiAgICAgIHJlY2VpdmVyIHtpZH0KICAgICAgb3V0cHV0T2Yge2lkfQogICAgICByZXNvdXJjZUNvbmZvcm1zVG8ge2lkfQogICAgICByZXNvdXJjZVF1YW50aXR5IHsKICAgICAgICBoYXNOdW1lcmljYWxWYWx1ZQogICAgICAgIGhhc1VuaXQge2lkfQogICAgICB9CiAgICAgIGF0TG9jYXRpb24ge2lkfQogICAgICBoYXNQb2ludEluVGltZQogICAgfQogICAgZWNvbm9taWNSZXNvdXJjZSB7ICMgdGhpcyBpcyB0aGUgbmV3bHktY3JlYXRlZCByZXNvdXJjZQogICAgICBpZAogICAgICBuYW1lCiAgICAgIG5vdGUKICAgICAgdHJhY2tpbmdJZGVudGlmaWVyCiAgICAgIHN0YWdlIHtpZH0KICAgICAgY3VycmVudExvY2F0aW9uIHtpZH0KICAgICAgY29uZm9ybXNUbyB7aWR9CiAgICAgIHByaW1hcnlBY2NvdW50YWJsZSB7aWR9CiAgICAgIGN1c3RvZGlhbiB7aWR9CiAgICAgIGFjY291bnRpbmdRdWFudGl0eSB7CiAgICAgICAgaGFzTnVtZXJpY2FsVmFsdWUKICAgICAgICBoYXNVbml0IHtpZH0KICAgICAgfQogICAgICBvbmhhbmRRdWFudGl0eSB7CiAgICAgICAgaGFzTnVtZXJpY2FsVmFsdWUKICAgICAgICBoYXNVbml0IHtpZH0KICAgICAgfQogICAgfQogIH0KfQo=","schnorr_signature":"CL7LFfLAIgE7e3U2KroR8q18EZ3KMCxaXpwE7MH+ZIpvIhAxIHrO9eZhRO6LQ9GAEtwdXnW04Q89O1eFo4C2JeFI/11i9rc7MjB3PIdBtUk="}
EOF

    cat <<EOF | zexe countchar.zen graphql.json
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
    save_output 'countchar.out'
}

@test "When I compact ascii strings in ''" {
    cat <<EOF | save_asset loremipsum.json
{"lorem": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?\nAt vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.\n\n"}
EOF

    cat <<EOF | zexe rmchar.zen loremipsum.json
Given I have a 'string' named 'lorem'
When I copy 'lorem' to 'ipsum'

When I remove newlines in 'lorem'
and I remove spaces in 'lorem'

When I compact ascii strings in 'ipsum'
and I verify 'lorem' is equal to 'ipsum'


Then print the string 'OK'
EOF
    save_output 'rmchar.out'
    assert_output '{"output":["OK"]}'
}

