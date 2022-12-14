load ../bats_setup
load ../bats_zencode
SUBDOC=branching

@test "Number comparison" {
    cat << EOF | save_asset number_comparison.json
{ "number_lower": 10,
  "number_higher": 50
}
EOF

    cat << EOF | zexe number_comparison.zen number_comparison.json
# Here we're loading the two numbers we have just defined
Given I have a 'number' named 'number_lower'
and I have a 'number' named 'number_higher'

# Here we try a simple comparison between the numbers
# if the condition is satisfied, the 'When' and 'Then' statements
# in the rest of the branch will be executed, which is not the case here.
If number 'number_lower' is more than 'number_higher'
When I create the random 'random_left_is_higher'
Then print string 'number_lower is higher'
Endif

# A simple comparison where the condition is satisfied, the 'When' and 'Then' statements are executed.
If number 'number_lower' is less than 'number_higher'
When I create the random 'just a random'
Then print string 'I promise that number_higher is higher than number_lower'
Endif

# We can also check if a certain number is less than or equal to another one
If number 'number_lower' is less or equal than 'number_higher'
Then print string 'the number_lower is less than or equal to number_higher'
Endif
# or if it is more than or equal to
If number 'number_lower' is more or equal than 'number_higher'
Then print string 'the number_lower is more than or equal to number_higher, imposssible!'
Endif

# Here we try a nested comparison: if the first condition is
# satisfied, the second one is evaluated too. Given the conditions,
# they can't both be true at the same time, so the rest of the branch won't be executed.
If number 'number_lower' is less than 'number_higher'
If I verify 'number_lower' is equal to 'number_higher'
When I create the random 'random_this_is_impossible'
Then print string 'the conditions can never be satisfied'
Endif

# You can also check if an object exists at a certain point of the execution, with the statement:
# If 'objectName' is found
If 'just a random' is found
Then print string 'I found the newly created random number, so I certify that the condition is satisfied'
Endif

When I create the random 'just a random in the main branch'
Then print all data
EOF
    save_output "number_comparison_output.json"
    assert_output '{"just_a_random":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","just_a_random_in_the_main_branch":"VyJ47aH6+hysFuthAZJP+LyFxmZs6L56Ru0P+JlCbDs=","number_higher":50,"number_lower":10,"output":["I_promise_that_number_higher_is_higher_than_number_lower","the_number_lower_is_less_than_or_equal_to_number_higher","I_found_the_newly_created_random_number,_so_I_certify_that_the_condition_is_satisfied"]}'
}

@test "Complex comparison" {
    cat << EOF | save_asset complex_comparison.json
{ "string_hello": "hello",
  "string_world": "world",
  "dictionary_equal" : { "1": "hello",
                         "2": "hello",
                         "3": "hello" },
  "dictionary_not_equal": { "1": "hello",
                            "2": "hello",
                            "3": "world" }
}
EOF

    cat << EOF | zexe complex_comparison.zen complex_comparison.json
# Here we're loading the two strings and the two arrays we have just defined
Given I have a 'string' named 'string_hello'
Given I have a 'string' named 'string_world'
Given I have a 'string dictionary' named 'dictionary_equal'
Given I have a 'string dictionary' named 'dictionary_not_equal'

# Here we try a simple comparison between the strings
If I verify 'string_hello' is equal to 'string_world'
Then print string 'string_hello is equal to string_world, impossible!'
Endif

# Here we try a simple comparison between the strings
If I verify 'string_hello' is not equal to 'string_world'
Then print string 'string_hello is not equal to string_world'
Endif

# Here we compare a string with an element of the dictionary
If I verify 'string_hello' is equal to '1' in 'dictionary equal'
Then print string 'string_hello is equal to the element with key equal to 1 in dictionary_equal'
Endif
If I verify 'string_hello' is not equal to '1' in 'dictionary equal'
Then print string 'string_hello is not equal to the element with key equal to 1 in dictionary_equal, impossible!'
Endif

# Here we check if all the elements in the dictionary are equal
# (it works also with arrays)
If the elements in 'dictionary_equal' are equal
Then print string 'all elements inside dictionary_equal are equal'
Endif

# Here we check if at least two elements in the dictionary are different
# (it works also with arrays)
If the elements in 'dictionary_not_equal' are not equal
Then print string 'all elements inside dictionary_not_equal are different'
Endif

EOF
    save_output "complex_comparison_output.json"
    assert_output '{"output":["string_hello_is_not_equal_to_string_world","string_hello_is_equal_to_the_element_with_key_equal_to_1_in_dictionary_equal","all_elements_inside_dictionary_equal_are_equal","all_elements_inside_dictionary_not_equal_are_different"]}'
}

@test "" {
    cat << EOF | save_asset leftrightB.json
{ "left": 60,
  "right": 50 }
EOF

    cat << EOF | zexe branchB.zen leftrightB.json
Given I have a 'number' named 'left'
and I have a 'number' named 'right'

If number 'left' is less than 'right'
and I verify 'right' is equal to 'right'
Then print string 'right is higher'
and print string 'and I am right'
endif

If number 'left' is more than 'right'
Then print string 'left is higher'
endif
EOF
    save_output "branchB.json"
    assert_output '{"output":["left_is_higher"]}'
}
@test "Found in array" {
    cat <<EOF | save_asset found.data
{
	"str": "good",
	"empty_arr": [],
	"not_empty_dict": {
		      "empty_octet":""
		      },
	"arr": ["hello",
		"goodmorning",
		"hi",
		"goodevening"],
	"dict": {
		"hello": "world",
		"nice": "world",
		"big": "world"
		}
}
EOF


    cat << EOF | zexe found.zen found.data
Given I have a 'string dictionary' named 'dict'
Given I have a 'string array' named 'arr'
Given I have a 'string dictionary' named 'not_empty_dict'
Given I have a 'string array' named 'empty_arr'
Given I have a 'string' named 'str'

When I create the 'string array' named 'found output'

If 'str' is found
When I insert string '1.success' in 'found output'
EndIf

If 'empty_arr' is found
When I insert string '2.success' in 'found output'
EndIf

If 'hello' is not found
When I insert string '3.success' in 'found output'
EndIf

If 'hello' is found in 'arr'
When I insert string '4.success' in 'found output'
EndIf

If 'hello' is found in 'dict'
When I insert string '5.success' in 'found output'
EndIf

If 'good' is not found in 'arr'
When I insert string '6.success' in 'found output'
EndIf

If 'good' is not found in 'dict'
When I insert string '7.success' in 'found output'
EndIf

If 'empty octet' is not found in 'not_empty_dict'
When I insert string '8.success' in 'found output'
EndIf


If 'hello' is found
When I insert string '1.fail' in 'found output'
EndIf

If 'str' is not found
When I insert string '2.fail' in 'found output'
EndIf

If 'good' is found in 'arr'
When I insert string '3.fail' in 'found output'
EndIf

If 'good' is found in 'dict'
When I insert string '4.fail' in 'found output'
EndIf

If 'hello' is not found in 'arr'
When I insert string '5.fail' in 'found output'
EndIf

If 'hello' is not found in 'dict'
When I insert string '6.fail' in 'found output'
EndIf

If 'hello' is found in 'empty arr'
When I insert string '7.fail' in 'found output'
EndIf

If 'empty_arr' is not found
When I insert string '8.fail' in 'found output'
EndIf

Then print 'found output'

EOF
    save_output 'found.json'
    assert_output '{"found_output":["1.success","2.success","3.success","4.success","5.success","6.success","7.success","8.success"]}'
}

@test "Print the" {
    cat <<EOF | save_asset print_the.data
{
	"W3C-DID": {
		"@context": [
			"https://www.w3.org/ns/did/v1",
			"https://dyne.github.io/W3C-DID/specs/EcdsaSecp256k1_b64.json",
			"https://dyne.github.io/W3C-DID/specs/ReflowBLS12381_b64.json",
			"https://dyne.github.io/W3C-DID/specs/SchnorrBLS12381_b64.json",
			"https://dyne.github.io/W3C-DID/specs/Dilithium2_b64.json",
			"https://w3id.org/security/suites/secp256k1-2020/v1",
			"https://w3id.org/security/suites/ed25519-2018/v1",
			{
				"Country": "https://schema.org/Country",
				"State": "https://schema.org/State",
				"description": "https://schema.org/description",
				"url": "https://schema.org/url"
			}
		],
		"Country": "IT",
		"State": "NONE",
		"alsoKnownAs": "did:dyne:fabchain:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=",
		"description": "restroom-mw",
		"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=",
		"proof": {
			"created": "1657122443982",
			"jws": "eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..cIr0MHc48KcwhMA9Uvvj_FISN4k579KKqh4IC-bHdsdbpbln1EHHXGqHrZkeAJBhXc_waA3FKkp3FGn4tABk_Q",
			"proofPurpose": "assertionMethod",
			"type": "EcdsaSecp256k1Signature2019",
			"verificationMethod": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=#key_ecdsa1"
		},
		"service": [
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-announce",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-announce",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/ethereum-to-ethereum-notarization.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-get-identity",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-get-identity",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-http-post",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-http-post",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-key-issuance.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-ping",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-ping",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/sawroom-to-ethereum-notarization.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-get-timestamp",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-update",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-update",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-get-signed-timestamp",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-get-signed-timestamp",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-sign-dilithium",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-dilithium",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-sign-ecdsa",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-ecdsa",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-sign-eddsa",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-eddsa",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-sign-schnorr",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-schnorr",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-dilithium-signature-verification-on-planetmint.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-dilithium-signature-verification-on-planetmint.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-execute-zencode-planetmint.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-execute-zencode-planetmint.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-post-6-rand-oracles.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-post-6-rand-oracles.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-read-from-fabric",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-read-from-fabric",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-write-on-fabric",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-write-on-fabric",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-read-from-ethereum",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-read-from-ethereum",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-write-on-ethereum.chain",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-write-on-ethereum.chain",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-read-from-planetmint",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-read-from-planetmint",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-write-on-planetmint",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-write-on-planetmint",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-verify-dilithium",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-dilithium",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-verify-ecdsa",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-ecdsa",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-verify-eddsa",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-eddsa",
				"type": "LinkedDomains"
			},
			{
				"id": "did:dyne:zenswarm-api#zenswarm-oracle-verify-schnorr",
				"serviceEndpoint": "https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-schnorr",
				"type": "LinkedDomains"
			}
		],
		"url": "https://swarm2.dyne.org",
		"verificationMethod": [
			{
				"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
				"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_ecdsa1",
				"publicKeyBase64": "BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=",
				"type": "EcdsaSecp256k1VerificationKey_b64"
			},
			{
				"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
				"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_reflow1",
				"publicKeyBase64": "Bt8/UBY/GgzSif1++9e1eFxDaTSP+7QIW1cgfyzlf/+iooUFfJStDw5ynNOfUOrmBjSFLu2hMn4CAXjCV/FFia34Jp+8Z/4CrFLS4LpvDcsrwlm/2hX6cSEXIE4leawBGe8XTAQVeevxaojtBRySxCWDcqHJxnWyF1IyoA/09fl/Xb26E1+S07q5cHp892B3BwbZYOJfA+gy2dz0xPMZdPoGoEdWlxnKQCo9a+DwfTLzTWqV5MR2eBK3qu/TBm80",
				"type": "ReflowBLS12381VerificationKey_b64"
			},
			{
				"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
				"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_schnorr1",
				"publicKeyBase64": "C5JbND4GMuxhlXhNqDOgz0ZW9VdG5SIbbDqaKBTgF+CJw5JRfAmiMeKGYXmclqGL",
				"type": "SchnorrBLS12381VerificationKey_b64"
			},
			{
				"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
				"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_dilithium1",
				"publicKeyBase64": "ozMr9XgGG3PxGQ3/l0hyr20jDN8CSU5siRDePjRjUvJKTC36YfVrxJlUfw2/GgLdOatVMvkXEco+LXNh09cGE3IC4ENI/pCWeLOr81j4iIWFgmrZhxvJAmJG7O7kdwFsv7KI1WtA3cKZ3OZ2JKmj8imHEZk4oXVKVnUDut/wLK40IiZRBgqmoR9X2ZJ9Um4IorwPzup/fPfDC6mGp4W8NvUsZGOcoYCehjmJIZRrDGAXRQ5iaWxWFZP0MbaqIKbqfnrS0XDdmFXiV/JIv1j1OpzWxNhhoU4rFodtFCqdiex06Y+fv6yidHOnc1fraVrTU2iSz9KkfwYDZ5uZK239q/bon1m5XUgItq79JN6mCjx865B2JuNmRSvR/e7EAVEqXA6gD3f9ic/f+T7m3M1buYMruCCB1kn79CMjeLEn7iCvAkVUS91lISsN6WzAI+1jq57ilOO0/vgLhrp9CrtktxdIrkNbtJlSiA5pHD3ZEsjnpLwt3wFe4W4EjlSWEuPa69kssFrrAgyv7PNBZi9aoDNcJt+OhRAk8iE/DxeKyxMo0wPacoWXC7wOj9aJ2FL2yoQMYnkgpIANUWqK39RmEJvkR4x+JI2HlndnIag5QvQD52N/KmHWPah4sqiqfumk4cWFmGyO5/o1ouPCqe5YfPJMPajp+NHK/8lmDM6VdWaYuJTRAzTrYtCLEFqklP4Czspo40mnagCh6KtOvnowy6U+x9Qe7VgnfOlef8iMDa77aJSDPM/WQ9cDz5+axT8Jw50DRPZpgMIzkBbbJMZWCqGISdpAUZmpYx42Q5ku8F6ajzx5Ph3Kt2BH0712cPQxF4PgRpjT6rMwGdAp9OGOzxGfzu78fCRdLod1Oo+PxpNaF1lhSDPzBdJrmIkDmMkGBmbwC67imHP/rHiXKIG2bLcLP2v705gFZ9Z8aASPR5LaXYMOBRMz5GPRZxfHPcutlkh4oZ8oIlB88wOBiQtybATW8qoiG7Ws0STGmjmnIcS1yybbihgW7cj0mU6hlJuo9jB6MfiDB6PEh0+FBK02eAFRgihaEme7u/BxoBzVA+kifgTwEN3oe0OUebWTtPUUeUcvGQytfuNyWFoEHrgcx3Ye2sLrFohDQr1GSj4GvQjiYMz0PKbfEnOT8np181VSawUoAQ+dqZMkhLj00HAi7hCbNFEuwO0e2GnC3Wvep35e3Gc2oOAAVSNgnMJD7WFUMbmy7gzMhYl3Ail+Ye29rCB8k5MNoS5VeyxOtaHN/fEl/wlcPNkvRfsb/41ZeqTpg274czvaT1JRRiDhjmPj5JJiLTCFjBDgKb4OVqLLPDNe51P/SzPch5ivkmkdF9wdTXH0BN1NUNV32DmFj3FNZg+1FgzMub/Yipz/9+oEQ9LkdPzR91EyNym4CAGarfuVsEsWQVpKqoQKnIfKnTAy43Tp9Klfqa8mh2A/UQh+btXJXeQ8zQrfFWIauqBbobHHglhmz6ePrCS/ftTqlSzGpoGDZNBmIctgT9R4Lx/Ira7wZpV4ZiALkfs1d5YNJP6hBQYH01g6Ax2m99toM0qirJE+BH+lrg/0Tfbjnu81aQZCutc4HfyNNZsAfKrCFdVpjkZ3VpBI0L7f12O2rNY1O1Kg1+4g58BroPrpwo2cYKVG022aUQULuTjSRAt39Ov3R6dWuwRNVKuTJZ/U8XPbk6dDnCDVR7jLF/kUjOjjc0zrqT/Kc7VR1MDpQxwnwtZ7DfxWFsvayiEcQQm/m3QZmA==",
				"type": "Dilithium2VerificationKey_b64"
			},
			{
				"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
				"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_eddsa1",
				"publicKeyBase58": "DehqMU9Yt5pMT4pLiBXsusawYV4LFjpr98X2GVhvDRJd",
				"type": "Ed25519VerificationKey2018"
			},
			{
				"blockchainAccountId": "eip155:1717658228:0x01ccaa74c6e3f6e29e82aa58ea90c48c237859e4",
				"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
				"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#fabchainAccountId",
				"type": "EcdsaSecp256k1RecoveryMethod2020"
			}
		]
	},
	"id": "did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM="
}
EOF

    cat <<EOF | zexe print_the.zen print_the.data
# Rule caller restroom-mw
Given I have a 'string' named 'id'
# Given I have a valid redis connection on 'redis://localhost:6379'
# Given I read from redis the data under the key named 'id' and save the output into 'W3C-DID'

Given I have a 'string array' named 'W3C-DID'

If the 'id' is not found in 'W3C-DID'
When I set 'title' to 'Identifier Not Found' as 'string'
When I set 'type' to 'about:blank' as 'string'
When I set 'status' to '404' as 'number'
Then print 'id'
Then print 'status'
Then print 'type'
Then print 'title'
Endif

If the 'id' is  found in 'W3C-DID'
Then print 'W3C-DID'
Then print the 'id'
Endif
EOF
    save_output 'print_the.json'
    assert_output '{"W3C-DID":{"@context":["https://www.w3.org/ns/did/v1","https://dyne.github.io/W3C-DID/specs/EcdsaSecp256k1_b64.json","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381_b64.json","https://dyne.github.io/W3C-DID/specs/SchnorrBLS12381_b64.json","https://dyne.github.io/W3C-DID/specs/Dilithium2_b64.json","https://w3id.org/security/suites/secp256k1-2020/v1","https://w3id.org/security/suites/ed25519-2018/v1",{"Country":"https://schema.org/Country","State":"https://schema.org/State","description":"https://schema.org/description","url":"https://schema.org/url"}],"Country":"IT","State":"NONE","alsoKnownAs":"did:dyne:fabchain:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=","description":"restroom-mw","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=","proof":{"created":"1657122443982","jws":"eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..cIr0MHc48KcwhMA9Uvvj_FISN4k579KKqh4IC-bHdsdbpbln1EHHXGqHrZkeAJBhXc_waA3FKkp3FGn4tABk_Q","proofPurpose":"assertionMethod","type":"EcdsaSecp256k1Signature2019","verificationMethod":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=#key_ecdsa1"},"service":[{"id":"did:dyne:zenswarm-api#zenswarm-oracle-announce","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-announce","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/ethereum-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-identity","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-get-identity","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-http-post","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-http-post","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-key-issuance.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-ping","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-ping","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/sawroom-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-get-timestamp","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-update","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-update","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-signed-timestamp","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-get-signed-timestamp","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-sign-dilithium","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-dilithium","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-sign-ecdsa","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-ecdsa","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-sign-eddsa","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-eddsa","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-sign-schnorr","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-sign-schnorr","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-dilithium-signature-verification-on-planetmint.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-dilithium-signature-verification-on-planetmint.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-execute-zencode-planetmint.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-execute-zencode-planetmint.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-post-6-rand-oracles.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-post-6-rand-oracles.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-read-from-fabric","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-read-from-fabric","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-write-on-fabric","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-write-on-fabric","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-read-from-ethereum","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-read-from-ethereum","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-write-on-ethereum.chain","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-write-on-ethereum.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-read-from-planetmint","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-read-from-planetmint","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-write-on-planetmint","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-write-on-planetmint","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-verify-dilithium","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-dilithium","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-verify-ecdsa","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-ecdsa","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-verify-eddsa","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-eddsa","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-verify-schnorr","serviceEndpoint":"https://swarm2.dyne.org:20001/api/zenswarm-oracle-verify-schnorr","type":"LinkedDomains"}],"url":"https://swarm2.dyne.org","verificationMethod":[{"controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_ecdsa1","publicKeyBase64":"BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=","type":"EcdsaSecp256k1VerificationKey_b64"},{"controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_reflow1","publicKeyBase64":"Bt8/UBY/GgzSif1++9e1eFxDaTSP+7QIW1cgfyzlf/+iooUFfJStDw5ynNOfUOrmBjSFLu2hMn4CAXjCV/FFia34Jp+8Z/4CrFLS4LpvDcsrwlm/2hX6cSEXIE4leawBGe8XTAQVeevxaojtBRySxCWDcqHJxnWyF1IyoA/09fl/Xb26E1+S07q5cHp892B3BwbZYOJfA+gy2dz0xPMZdPoGoEdWlxnKQCo9a+DwfTLzTWqV5MR2eBK3qu/TBm80","type":"ReflowBLS12381VerificationKey_b64"},{"controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_schnorr1","publicKeyBase64":"C5JbND4GMuxhlXhNqDOgz0ZW9VdG5SIbbDqaKBTgF+CJw5JRfAmiMeKGYXmclqGL","type":"SchnorrBLS12381VerificationKey_b64"},{"controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_dilithium1","publicKeyBase64":"ozMr9XgGG3PxGQ3/l0hyr20jDN8CSU5siRDePjRjUvJKTC36YfVrxJlUfw2/GgLdOatVMvkXEco+LXNh09cGE3IC4ENI/pCWeLOr81j4iIWFgmrZhxvJAmJG7O7kdwFsv7KI1WtA3cKZ3OZ2JKmj8imHEZk4oXVKVnUDut/wLK40IiZRBgqmoR9X2ZJ9Um4IorwPzup/fPfDC6mGp4W8NvUsZGOcoYCehjmJIZRrDGAXRQ5iaWxWFZP0MbaqIKbqfnrS0XDdmFXiV/JIv1j1OpzWxNhhoU4rFodtFCqdiex06Y+fv6yidHOnc1fraVrTU2iSz9KkfwYDZ5uZK239q/bon1m5XUgItq79JN6mCjx865B2JuNmRSvR/e7EAVEqXA6gD3f9ic/f+T7m3M1buYMruCCB1kn79CMjeLEn7iCvAkVUS91lISsN6WzAI+1jq57ilOO0/vgLhrp9CrtktxdIrkNbtJlSiA5pHD3ZEsjnpLwt3wFe4W4EjlSWEuPa69kssFrrAgyv7PNBZi9aoDNcJt+OhRAk8iE/DxeKyxMo0wPacoWXC7wOj9aJ2FL2yoQMYnkgpIANUWqK39RmEJvkR4x+JI2HlndnIag5QvQD52N/KmHWPah4sqiqfumk4cWFmGyO5/o1ouPCqe5YfPJMPajp+NHK/8lmDM6VdWaYuJTRAzTrYtCLEFqklP4Czspo40mnagCh6KtOvnowy6U+x9Qe7VgnfOlef8iMDa77aJSDPM/WQ9cDz5+axT8Jw50DRPZpgMIzkBbbJMZWCqGISdpAUZmpYx42Q5ku8F6ajzx5Ph3Kt2BH0712cPQxF4PgRpjT6rMwGdAp9OGOzxGfzu78fCRdLod1Oo+PxpNaF1lhSDPzBdJrmIkDmMkGBmbwC67imHP/rHiXKIG2bLcLP2v705gFZ9Z8aASPR5LaXYMOBRMz5GPRZxfHPcutlkh4oZ8oIlB88wOBiQtybATW8qoiG7Ws0STGmjmnIcS1yybbihgW7cj0mU6hlJuo9jB6MfiDB6PEh0+FBK02eAFRgihaEme7u/BxoBzVA+kifgTwEN3oe0OUebWTtPUUeUcvGQytfuNyWFoEHrgcx3Ye2sLrFohDQr1GSj4GvQjiYMz0PKbfEnOT8np181VSawUoAQ+dqZMkhLj00HAi7hCbNFEuwO0e2GnC3Wvep35e3Gc2oOAAVSNgnMJD7WFUMbmy7gzMhYl3Ail+Ye29rCB8k5MNoS5VeyxOtaHN/fEl/wlcPNkvRfsb/41ZeqTpg274czvaT1JRRiDhjmPj5JJiLTCFjBDgKb4OVqLLPDNe51P/SzPch5ivkmkdF9wdTXH0BN1NUNV32DmFj3FNZg+1FgzMub/Yipz/9+oEQ9LkdPzR91EyNym4CAGarfuVsEsWQVpKqoQKnIfKnTAy43Tp9Klfqa8mh2A/UQh+btXJXeQ8zQrfFWIauqBbobHHglhmz6ePrCS/ftTqlSzGpoGDZNBmIctgT9R4Lx/Ira7wZpV4ZiALkfs1d5YNJP6hBQYH01g6Ax2m99toM0qirJE+BH+lrg/0Tfbjnu81aQZCutc4HfyNNZsAfKrCFdVpjkZ3VpBI0L7f12O2rNY1O1Kg1+4g58BroPrpwo2cYKVG022aUQULuTjSRAt39Ov3R6dWuwRNVKuTJZ/U8XPbk6dDnCDVR7jLF/kUjOjjc0zrqT/Kc7VR1MDpQxwnwtZ7DfxWFsvayiEcQQm/m3QZmA==","type":"Dilithium2VerificationKey_b64"},{"controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#key_eddsa1","publicKeyBase58":"DehqMU9Yt5pMT4pLiBXsusawYV4LFjpr98X2GVhvDRJd","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1717658228:0x01ccaa74c6e3f6e29e82aa58ea90c48c237859e4","controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=","id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM=#fabchainAccountId","type":"EcdsaSecp256k1RecoveryMethod2020"}]},"id":"did:dyne:id:BI9xe74Y7038gyb4XvC8EM/4wkodgTGFDv8w72wwtlHcHxib4IHphvG9hd0+IMP9+RjRUPt1LRR3LZoySlCRhmM="}'

}

@test "verify starts and ends with" {
    cat << EOF | save_asset start_end.data
{
  "str": "did:dyne:who?",
  "sub": "did:dyne:"
}
EOF

    cat << EOF | zexe start_end.zen start_end.data
Given I have a 'string' named 'str'
and I have a 'string' named 'sub'

When I create the 'string array' named 'results'

If I verify 'str' starts with 'sub'
When I insert string 'str starts with sub' in 'results'
endif

If I verify 'str' ends with 'who?'
When I insert string 'str ends with string who?' in 'results'
endif

If I verify 'str' ends with 'sub'
When I insert string 'str ends with sub' in 'results'
endif

If I verify 'str' starts with 'did:dyne*'
When I insert string 'str starts with string did:dyne*' in 'results'
endif

Then print the 'results'

EOF
    save_output "start_end.out"
    assert_output '{"results":["str_starts_with_sub","str_ends_with_string_who?"]}'
}
