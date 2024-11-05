load ../bats_setup
load ../bats_zencode
SUBDOC=sd_jwt

@test "Import metadata" {
    cat <<EOF | save_asset metadata.keys.json
{
    "supported_selective_disclosure":{
        "credential_endpoint":"http://issuer.example.org/credentials",
        "credential_issuer":"http://issuer.example.org",
        "authorization_servers":[
            "http://server.example.org"
        ],
        "credential_configurations_supported":{
            "IdentityCredential":{
                "credential_signing_alg_values_supported":[
                    "ES256"
                ],
                "cryptographic_binding_methods_supported":[
                    "jwk",
                    "did:dyne:sandbox.signroom"
                ],
                "display":[
                    {
                        "background_color":"#000000",
                        "locale":"en-US",
                        "name":"IdentityCredential",
                        "text_color":"#ffffff"
                    }
                ],
                "format":"vc+sd-jwt",
                "proof_types_supported":{
                    "jwt":{
                        "proof_signing_alg_values_supported":[
                            "ES256"
                        ]
                    }
                },
                "vct": "IdentityCredential",
                "claims":{
                    "family_name":{
                        "display":[
                            {
                                "locale":"en-US",
                                "name":"Family Name"
                            }
                        ]
                    },
                    "given_name":{
                        "display":[
                            {
                                "locale":"en-US",
                                "name":"Given Name"
                            }
                        ]
                    }
                }
            }
        }
    }
}
EOF
    cat <<EOF | zexe metadata.zen metadata.keys.json
Scenario 'sd_jwt': sign JSON
Given I have a 'supported selective disclosure'
Then print data
EOF
    save_output 'metadata.out.json'
    assert_output "$(cat metadata.keys.json | jq -c --sort-keys)"
}

@test "Import and export SDR" {
    cat <<EOF | save_asset valid_sdr.data.json
{"selective_disclosure_request":{"fields":["given_name","age","family_name"],"object":{"age":42,"degree":"math","family_name":"Lippo","given_name":"Mimmo","iss":"http://example.org","sub":"user 42"}}}
EOF
    cat <<EOF | zexe valid_sdr.zen valid_sdr.data.json
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
Then print data
EOF
    save_output valid_sdr.out.json
    assert_output "$(cat valid_sdr.data.json)"
}

@test "Fail import SDR for disclosing claim not in object" {
    cat <<EOF | save_asset invalid_sdr2.data.json
{"selective_disclosure_request":{"fields":["given_name","age","address"],"object":{"age":42,"family_name":"Lippo","given_name":"Mimmo"}}}
EOF
    cat <<EOF | save_asset invalid_sdr.zen
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
Then print data
EOF

    run $ZENROOM_EXECUTABLE -z -a invalid_sdr2.data.json invalid_sdr.zen
    assert_line --partial 'is not a key in the object'
}

@test "Fail import SDR because 'fields' is not a string array" {
    cat <<EOF | save_asset invalid_sdr3.data.json
{"selective_disclosure_request":{"fields":["given_name","age",{"address": "street"}],"object":{"age":42,"family_name":"Lippo","given_name":"Mimmo"}}}
EOF
    run $ZENROOM_EXECUTABLE -z -a invalid_sdr3.data.json invalid_sdr.zen
    assert_line --partial 'The object with key fields must be a string array'
}

@test "SSD to SDR" {
    cat <<EOF | save_asset object.data.json
{"object":{"age":42,"degree":"math","family_name":"Lippo","given_name":"Mimmo","iss":"http://example.org","sub":"user 42"}, "id": "IdentityCredential"}
EOF
    cat <<EOF | zexe ssd_to_sdr.zen object.data.json metadata.keys.json
Scenario 'sd_jwt'

Given I have 'supported_selective_disclosure'
Given I have a 'string' named 'id'
Given I have a 'string dictionary' named 'object'
When I create the selective disclosure request from 'supported_selective_disclosure' with id 'id' for 'object'
Then print the 'selective_disclosure_request'
EOF
    save_output ssd_to_sdr.out.json
    assert_output '{"selective_disclosure_request":{"fields":["family_name","given_name"],"object":{"age":42,"degree":"math","family_name":"Lippo","given_name":"Mimmo","iss":"http://example.org","sub":"user 42"}}}'
}

@test "Create SD Payload" {
    cat <<EOF | save_asset sd_payload.data.json
{   
    "The Issuer": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==",
        "keyring":{"es256":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}
    },
    "selective_disclosure_request": {
        "fields":[
            "given_name","family_name","email","phone_number",
            "phone_number_verified","address","birthdate","updated_at"
        ],
        "object": {
            "iss": "https://issuer.example.com",
            "iat": 1683000000,
            "exp": 1883000000,
            "given_name": "John",
            "family_name": "Doe",
            "email": "johndoe@example.com",
            "phone_number": "+1-202-555-0101",
            "phone_number_verified": true,
            "address": {
                "street_address": "123 Main St",
                "locality": "Anytown",
                "region": "Anystate",
                "country": "US"
            },
            "birthdate": "1940-01-01",
            "updated_at": 1570000000,
            "nationalities": [
                "US",
                "DE"
            ],
            "iss":"http://example.org",
            "sub":"user 42"
        }
    }
}
EOF
    cat <<EOF | zexe sd_payload.zen sd_payload.data.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'The Issuer'
and I have my 'keyring'
and I have my 'es256 public key'

Given I have 'selective_disclosure_request'

When I create the selective disclosure of 'selective_disclosure_request'
When I create the signed selective disclosure of 'selective disclosure'
Then print the 'signed selective disclosure' as 'decoded selective disclosure'
Then print the 'es256 public key'
Then print the 'selective disclosure request'
Then print the 'selective disclosure'
Then print the 'keyring'
EOF
    save_output sd_payload.out.json
    assert_output '{"es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==","keyring":{"es256":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="},"selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"],["Ll27jjwT4yzd0i-7NGdZAw","updated_at",1570000000]],"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"}},"selective_disclosure_request":{"fields":["given_name","family_name","email","phone_number","phone_number_verified","address","birthdate","updated_at"],"object":{"address":{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"},"birthdate":"1940-01-01","email":"johndoe@example.com","exp":1883000000,"family_name":"Doe","given_name":"John","iat":1683000000,"iss":"http://example.org","nationalities":["US","DE"],"phone_number":"+1-202-555-0101","phone_number_verified":true,"sub":"user 42","updated_at":1570000000}},"signed_selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"],["Ll27jjwT4yzd0i-7NGdZAw","updated_at",1570000000]],"jwt":{"header":{"alg":"ES256","typ":"vc+sd-jwt"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},"signature":"bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgZLMOV-TnEy_FSpyqsMXT-qqSj7ZIdca8tWrZrwZT72w"}}}'
}

@test "Import and export SD Payload" {

    cat <<EOF | zexe sd_payload2.zen sd_payload.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I have 'keyring'
Given I have the 'es256 public key'
Given I have 'selective_disclosure_request'
Given I have 'selective_disclosure'
Given I have a 'decoded selective disclosure' named 'signed selective disclosure'

Then print data
Then print the 'keyring'
EOF
    save_output sd_payload2.out.json
    assert_output "$(cat sd_payload.out.json)"
}

@test "Create selective disclosure presentation" {
    cat <<EOF | save_asset some_disclo.json
{
    "some_disclosure":["given_name", "phone_number"]
}
EOF
    cat <<EOF | zexe sd_presentation.zen some_disclo.json sd_payload2.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I have a 'decoded selective disclosure' named 'signed selective disclosure'
Given I have a 'string array' named 'some disclosure'

When I use signed selective disclosure 'signed selective disclosure' only with disclosures 'some disclosure'

Then print 'signed selective disclosure' as 'decoded selective disclosure'

EOF
    save_output sd_presentation.out.json
    assert_output '{"signed_selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"]],"jwt":{"header":{"alg":"ES256","typ":"vc+sd-jwt"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},"signature":"bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgZLMOV-TnEy_FSpyqsMXT-qqSj7ZIdca8tWrZrwZT72w"}}}'
}

@test "verify disclosures are found in signed selective disclosure" {
    cat <<EOF | save_asset verify_disclosure.json
{
    "present_disclosure":["given_name", "phone_number"],
    "single_present_disclosure": "given_name",
    "missing_disclosure":["given_name", "phone_number", "age"],
    "single_missing_disclosure": "age"
}
EOF
    cat <<EOF | zexe verify_disclosure.zen verify_disclosure.json sd_payload2.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I have a 'decoded selective disclosure' named 'signed selective disclosure'
Given I have a 'string array' named 'present_disclosure'
Given I have a 'string' named 'single_present_disclosure'
Given I have a 'string array' named 'missing_disclosure'
Given I have a 'string' named 'single_missing_disclosure'

If I verify disclosures 'present_disclosure' are found in signed selective disclosure 'signed selective disclosure'
Then print the 'present_disclosure'
EndIf
If I verify disclosures 'single_present_disclosure' are found in signed selective disclosure 'signed selective disclosure'
Then print the 'single_present_disclosure'
EndIf
If I verify disclosures 'missing_disclosure' are found in signed selective disclosure 'signed selective disclosure'
Then print the 'missing_disclosure'
EndIf
If I verify disclosures 'single_missing_disclosure' are found in signed selective disclosure 'signed selective disclosure'
Then print the 'single_missing_disclosure'
EndIf
EOF
    save_output verify_disclosure.out.json
    assert_output '{"present_disclosure":["given_name","phone_number"],"single_present_disclosure":"given_name"}'
    cat <<EOF | save_asset verify_disclosure_fail.zen
Scenario 'sd_jwt'
Scenario 'es256'

Given I have a 'decoded selective disclosure' named 'signed selective disclosure'
Given I have a 'string array' named 'missing_disclosure'

When I verify disclosures 'missing_disclosure' are found in signed selective disclosure 'signed selective disclosure' 

Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z -a verify_disclosure.json -k sd_payload2.out.json verify_disclosure_fail.zen
    assert_line --partial 'Disclosure key not found: age'
}

@test "Verify the validity of signed sd-jwt" {
    cat <<EOF | save_asset alice_es256_keys.json
{
    "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
}
EOF
    cat <<EOF | save_asset sd_verification.zen
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have a 'decoded selective disclosure' named 'signed selective disclosure'

When I verify signed selective disclosure 'signed_selective_disclosure' issued by 'Alice' is valid

Then print data

EOF
    cat <<EOF | zexe sd_verification.zen alice_es256_keys.json sd_payload2.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have a 'decoded selective disclosure' named 'signed selective disclosure'

When I verify signed selective disclosure 'signed_selective_disclosure' issued by 'Alice' is valid

Then print data

EOF
    save_output sd_verification.out.json
    assert_output '{"es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==","signed_selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"],["Ll27jjwT4yzd0i-7NGdZAw","updated_at",1570000000]],"jwt":{"header":{"alg":"ES256","typ":"vc+sd-jwt"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},"signature":"bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgZLMOV-TnEy_FSpyqsMXT-qqSj7ZIdca8tWrZrwZT72w"}}}'
}

@test "Verify selective disclosure presentation" {
    cat <<EOF | zexe ver_presentation.zen alice_es256_keys.json sd_presentation.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have a 'decoded selective disclosure' named 'signed selective disclosure'

When I verify signed selective disclosure 'signed_selective_disclosure' issued by 'Alice' is valid

Then print data

EOF
    save_output ver_presentation.out.json
    assert_output '{"es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==","signed_selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"]],"jwt":{"header":{"alg":"ES256","typ":"vc+sd-jwt"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},"signature":"bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgZLMOV-TnEy_FSpyqsMXT-qqSj7ZIdca8tWrZrwZT72w"}}}'
}

@test "Fail verify on invalid sd-jwt: wrong header" {
    cat <<EOF | save_asset wrong_header.json
{
    "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
    "signed_selective_disclosure":{
        "disclosures":[["VyJ47aH6-hysFuthAZJP-A","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","family_name","Doe"],["5XsSIXmaZbf5ikQgMSVGjQ","email","johndoe@example.com"],["br5gmh-cSRNAvocKCmAD0A","phone_number","+1-202-555-0101"],["6UasczRKmme8SOUwelXq2w","phone_number_verified",true],["Ll27jjwT4yzd0i-7NGdZAw","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["DR92VSF2l3Az1K1-LyWO1w","birthdate","1940-01-01"]],
        "jwt":{
            "header":{"alg":"ES356","typ":"JWT"},
            "payload":{"_sd":["cMZilhOF9uEyvW_vCKx8IkbqfmntjqkV8HCFQ_lgPq0","DjUC3iXDmUj0QQgbZM7PQhhOLI3EjqSNzz3IhCpqQhg","wyoSepSkpJXnOxKlsypeqjr9PMFXf024GlIBPgVKnrg","MW58zqUyooJw5zGmASCETNi4qORcewuTRWDhLMLavis","sftnu87bkbl62AB38gmuyQdX5yD95TxMuzhvyiD7Wb8","dydbjYL8bcTkcXtLZ2e8514B7n7QDnOgOWD5Fniwjdo","84Vp4ymg-8VScgYletGB4TfHboLPkIXLaP3djL2Km0U"],
                        "_sd_alg":"sha-256",
                        "iss":"http://example.org",
                        "sub":"user 42"
                    },
            "signature":"zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4-Ai8uCNZgm-KpfpBANXo5NB2x2oWjqiWA"
        }
    }
}
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_header.json sd_verification.zen
    assert_line --partial 'The JWT header is not valid'
}

@test "Fail verify on invalid sd-jwt: wrong signature" {
    cat <<EOF | save_asset wrong_sig.json
{
    "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
    "signed_selective_disclosure":{
        "disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"],["Ll27jjwT4yzd0i-7NGdZAw","updated_at",1570000000]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},
            "signature":"VRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgR11pTSVPQUIuK0URkzBCfxwnfGe0de-rIIIkUPhsLlg"
            }
    }
}
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_sig.json sd_verification.zen
    assert_line --partial 'The issuer signature is not valid'
}

@test "Fail verify on invalid sd-jwt: wrong issuer pk" {
    cat <<EOF | save_asset wrong_pk.json
{
    "Alice": {
        "es256_public_key":"gMKKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
    "signed_selective_disclosure":{
        "disclosures":[["VyJ47aH6-hysFuthAZJP-A","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","family_name","Doe"],["5XsSIXmaZbf5ikQgMSVGjQ","email","johndoe@example.com"],["br5gmh-cSRNAvocKCmAD0A","phone_number","+1-202-555-0101"],["6UasczRKmme8SOUwelXq2w","phone_number_verified",true],["Ll27jjwT4yzd0i-7NGdZAw","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["DR92VSF2l3Az1K1-LyWO1w","birthdate","1940-01-01"]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["cMZilhOF9uEyvW_vCKx8IkbqfmntjqkV8HCFQ_lgPq0","DjUC3iXDmUj0QQgbZM7PQhhOLI3EjqSNzz3IhCpqQhg","wyoSepSkpJXnOxKlsypeqjr9PMFXf024GlIBPgVKnrg","MW58zqUyooJw5zGmASCETNi4qORcewuTRWDhLMLavis","sftnu87bkbl62AB38gmuyQdX5yD95TxMuzhvyiD7Wb8","dydbjYL8bcTkcXtLZ2e8514B7n7QDnOgOWD5Fniwjdo","84Vp4ymg-8VScgYletGB4TfHboLPkIXLaP3djL2Km0U"],
                        "_sd_alg":"sha-256",
                        "iss":"http://example.org",
                        "sub":"user 42"
                    },
            "signature":"zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4-Ai8uCNZgm-KpfpBANXo5NB2x2oWjqiWA"
        }
    }
}
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_pk.json sd_verification.zen
    assert_line --partial 'The issuer signature is not valid'
}

@test "Fail verify on invalid sd-jwt: wrong disclosure" {
    cat <<EOF | save_asset wrong_dis.json
{
    "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },   
    "signed_selective_disclosure":{
        "disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"],["Ll27jjwT4yzd0i-7NGdZAw","updated_at",1570000000]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKGy","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},
            "signature":"bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgR11pTSVPQUIuK0URkzBCfxwnfGe0de-rIIIkUPhsLlg"
            }
    }
}
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_dis.json sd_verification.zen
    assert_line --partial 'The disclosure is not valid'
}

@test "Fail verify on invalid sd-jwt: wrong disclosure array" {
    cat <<EOF | save_asset wrong_dis_arr.json
{
    "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    }, 
    "signed_selective_disclosure":{
        "disclosures":[["XdjAYj-RY95-uyYMI8fR3w","name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"],["Ll27jjwT4yzd0i-7NGdZAw","updated_at",1570000000]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo","GRAVzz7ZmE5-g1siHKrMLibaQQKdgkJGitjrx1D0JBs"],"_sd_alg":"sha-256","exp":1883000000,"iat":1683000000,"iss":"http://example.org","sub":"user 42"},
            "signature":"bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgR11pTSVPQUIuK0URkzBCfxwnfGe0de-rIIIkUPhsLlg"
            }
    }
}
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_dis_arr.json sd_verification.zen
    assert_line --partial 'The disclosure is not valid'
}

@test "Import and export SD JWT encoded" {
    cat <<EOF | save_asset 'sd-jwt.data.json'
{"signed_selective_disclosure":"eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJfc2QiOlsiY01aaWxoT0Y5dUV5dldfdkNLeDhJa2JxZm1udGpxa1Y4SENGUV9sZ1BxMCIsIkRqVUMzaVhEbVVqMFFRZ2JaTTdQUWhoT0xJM0VqcVNOenozSWhDcHFRaGciLCJ3eW9TZXBTa3BKWG5PeEtsc3lwZXFqcjlQTUZYZjAyNEdsSUJQZ1ZLbnJnIiwiTVc1OHpxVXlvb0p3NXpHbUFTQ0VUTmk0cU9SY2V3dVRSV0RoTE1MYXZpcyIsInNmdG51ODdia2JsNjJBQjM4Z211eVFkWDV5RDk1VHhNdXpodnlpRDdXYjgiLCJkeWRiallMOGJjVGtjWHRMWjJlODUxNEI3bjdRRG5PZ09XRDVGbml3amRvIiwiODRWcDR5bWctOFZTY2dZbGV0R0I0VGZIYm9MUGtJWExhUDNkakwyS20wVSJdLCJfc2RfYWxnIjoic2hhLTI1NiIsImlzcyI6Imh0dHA6Ly9leGFtcGxlLm9yZyIsInN1YiI6InVzZXIgNDIifQ.zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4-Ai8uCNZgm-KpfpBANXo5NB2x2oWjqiWA~WyJWeUo0N2FINi1oeXNGdXRoQVpKUC1BIiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyJ2SVhHWm16b3ZucEc3UV80bVVKc093IiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyI1WHNTSVhtYVpiZjVpa1FnTVNWR2pRIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~WyJicjVnbWgtY1NSTkF2b2NLQ21BRDBBIiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ~WyI2VWFzY3pSS21tZThTT1V3ZWxYcTJ3IiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd~WyJMbDI3amp3VDR5emQwaS03TkdkWkF3IiwgImFkZHJlc3MiLCB7ImNvdW50cnkiOiAiVVMiLCAibG9jYWxpdHkiOiAiQW55dG93biIsICJyZWdpb24iOiAiQW55c3RhdGUiLCAic3RyZWV0X2FkZHJlc3MiOiAiMTIzIE1haW4gU3QifV0~WyJEUjkyVlNGMmwzQXoxSzEtTHlXTzF3IiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0~"}
EOF
    cat <<EOF | zexe sd_jwt_encoded sd-jwt.data.json
Scenario 'sd_jwt'

Given I have a 'signed selective disclosure'
Then print the 'signed selective disclosure'
EOF
    save_output sd_jwt_encoded.out.json
    assert_output '{"signed_selective_disclosure":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogIkpXVCJ9.eyJfc2QiOiBbImNNWmlsaE9GOXVFeXZXX3ZDS3g4SWticWZtbnRqcWtWOEhDRlFfbGdQcTAiLCAiRGpVQzNpWERtVWowUVFnYlpNN1BRaGhPTEkzRWpxU056ejNJaENwcVFoZyIsICJ3eW9TZXBTa3BKWG5PeEtsc3lwZXFqcjlQTUZYZjAyNEdsSUJQZ1ZLbnJnIiwgIk1XNTh6cVV5b29KdzV6R21BU0NFVE5pNHFPUmNld3VUUldEaExNTGF2aXMiLCAic2Z0bnU4N2JrYmw2MkFCMzhnbXV5UWRYNXlEOTVUeE11emh2eWlEN1diOCIsICJkeWRiallMOGJjVGtjWHRMWjJlODUxNEI3bjdRRG5PZ09XRDVGbml3amRvIiwgIjg0VnA0eW1nLThWU2NnWWxldEdCNFRmSGJvTFBrSVhMYVAzZGpMMkttMFUiXSwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJpc3MiOiAiaHR0cDovL2V4YW1wbGUub3JnIiwgInN1YiI6ICJ1c2VyIDQyIn0.zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4-Ai8uCNZgm-KpfpBANXo5NB2x2oWjqiWA~WyJWeUo0N2FINi1oeXNGdXRoQVpKUC1BIiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyJ2SVhHWm16b3ZucEc3UV80bVVKc093IiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyI1WHNTSVhtYVpiZjVpa1FnTVNWR2pRIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~WyJicjVnbWgtY1NSTkF2b2NLQ21BRDBBIiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ~WyI2VWFzY3pSS21tZThTT1V3ZWxYcTJ3IiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd~WyJMbDI3amp3VDR5emQwaS03TkdkWkF3IiwgImFkZHJlc3MiLCB7ImNvdW50cnkiOiAiVVMiLCAibG9jYWxpdHkiOiAiQW55dG93biIsICJyZWdpb24iOiAiQW55c3RhdGUiLCAic3RyZWV0X2FkZHJlc3MiOiAiMTIzIE1haW4gU3QifV0~WyJEUjkyVlNGMmwzQXoxSzEtTHlXTzF3IiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0~"}'
}

@test "Verify SD JWT encoded" {
        cat <<EOF | save_asset 'ver-sd-jwt.data.json'
{   "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
    "signed_selective_disclosure":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbInQwQ2h1cDYyZmlhRDZTd3pfWllIdTR2YmhJRU9UaWdWZzd6Mmx5TkJLZ1kiLCAiV19WeFZLR2YxX25jV2ZBalJvSlVHeDdZZUhSaEt6Yl91Y1ZoQ0xVNjlEYyIsICJQdGVORDVEZHdINnlCdXhVS0Qza3BTVFdVTlppRE5JQ3hNdzNsOUxYSlE4IiwgIndweVV3N2tEREVUSmZNbm5iQjc0Vm5vbGNUSXcxYWNGRHBRaUFuR1V3cVEiLCAicWROXzY3aTEyaDFJdXZBUlFxNjdyQ1d4ZC11UElBOThIUmphaXEySHl3TSIsICJtRnRGT1M0WjJjaUdSWnBzQWZzU1I3R0xpX3FiM0lGYmlRU2hFOUR3UlVZIiwgIm5CWnQzaEFxQkk1Q1BVSlJFek1sWGRaaDZ0cmlUa1dzMmRzU1hUZkx6bG8iLCAiR1JBVnp6N1ptRTUtZzFzaUhLck1MaWJhUVFLZGdrSkdpdGpyeDFEMEpCcyJdLCAiX3NkX2FsZyI6ICJzaGEtMjU2IiwgImV4cCI6IDE4ODMwMDAwMDAsICJpYXQiOiAxNjgzMDAwMDAwLCAiaXNzIjogImh0dHA6Ly9leGFtcGxlLm9yZyIsICJzdWIiOiAidXNlciA0MiJ9.bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgZLMOV-TnEy_FSpyqsMXT-qqSj7ZIdca8tWrZrwZT72w~WyJYZGpBWWotUlk5NS11eVlNSThmUjN3IiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyI1LVlfa3ZKQm8zbmlfSk5OVXJGbklBIiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyJWeUo0N2FINi1oeXNGdXRoQVpKUC1BIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~WyJ2SVhHWm16b3ZucEc3UV80bVVKc093IiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ~WyI1WHNTSVhtYVpiZjVpa1FnTVNWR2pRIiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd~WyJicjVnbWgtY1NSTkF2b2NLQ21BRDBBIiwgImFkZHJlc3MiLCB7ImNvdW50cnkiOiAiVVMiLCAibG9jYWxpdHkiOiAiQW55dG93biIsICJyZWdpb24iOiAiQW55c3RhdGUiLCAic3RyZWV0X2FkZHJlc3MiOiAiMTIzIE1haW4gU3QifV0~WyI2VWFzY3pSS21tZThTT1V3ZWxYcTJ3IiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0~WyJMbDI3amp3VDR5emQwaS03TkdkWkF3IiwgInVwZGF0ZWRfYXQiLCAxNTcwMDAwMDAwXQ~"}
EOF
    cat <<EOF | zexe verify_sd_jwt_encoded ver-sd-jwt.data.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have a 'signed selective disclosure'
When I verify signed selective disclosure 'signed_selective_disclosure' issued by 'Alice' is valid
Then print the 'signed selective disclosure'
EOF
    save_output verify_sd_jwt_encoded.out.json
    assert_output '{"signed_selective_disclosure":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbInQwQ2h1cDYyZmlhRDZTd3pfWllIdTR2YmhJRU9UaWdWZzd6Mmx5TkJLZ1kiLCAiV19WeFZLR2YxX25jV2ZBalJvSlVHeDdZZUhSaEt6Yl91Y1ZoQ0xVNjlEYyIsICJQdGVORDVEZHdINnlCdXhVS0Qza3BTVFdVTlppRE5JQ3hNdzNsOUxYSlE4IiwgIndweVV3N2tEREVUSmZNbm5iQjc0Vm5vbGNUSXcxYWNGRHBRaUFuR1V3cVEiLCAicWROXzY3aTEyaDFJdXZBUlFxNjdyQ1d4ZC11UElBOThIUmphaXEySHl3TSIsICJtRnRGT1M0WjJjaUdSWnBzQWZzU1I3R0xpX3FiM0lGYmlRU2hFOUR3UlVZIiwgIm5CWnQzaEFxQkk1Q1BVSlJFek1sWGRaaDZ0cmlUa1dzMmRzU1hUZkx6bG8iLCAiR1JBVnp6N1ptRTUtZzFzaUhLck1MaWJhUVFLZGdrSkdpdGpyeDFEMEpCcyJdLCAiX3NkX2FsZyI6ICJzaGEtMjU2IiwgImV4cCI6IDE4ODMwMDAwMDAsICJpYXQiOiAxNjgzMDAwMDAwLCAiaXNzIjogImh0dHA6Ly9leGFtcGxlLm9yZyIsICJzdWIiOiAidXNlciA0MiJ9.bRd93MYGuiVye_3QVLtvyxGmyGejx_HXQcC-z3m_PtgZLMOV-TnEy_FSpyqsMXT-qqSj7ZIdca8tWrZrwZT72w~WyJYZGpBWWotUlk5NS11eVlNSThmUjN3IiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyI1LVlfa3ZKQm8zbmlfSk5OVXJGbklBIiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyJWeUo0N2FINi1oeXNGdXRoQVpKUC1BIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~WyJ2SVhHWm16b3ZucEc3UV80bVVKc093IiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ~WyI1WHNTSVhtYVpiZjVpa1FnTVNWR2pRIiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd~WyJicjVnbWgtY1NSTkF2b2NLQ21BRDBBIiwgImFkZHJlc3MiLCB7ImNvdW50cnkiOiAiVVMiLCAibG9jYWxpdHkiOiAiQW55dG93biIsICJyZWdpb24iOiAiQW55c3RhdGUiLCAic3RyZWV0X2FkZHJlc3MiOiAiMTIzIE1haW4gU3QifV0~WyI2VWFzY3pSS21tZThTT1V3ZWxYcTJ3IiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0~WyJMbDI3amp3VDR5emQwaS03TkdkWkF3IiwgInVwZGF0ZWRfYXQiLCAxNTcwMDAwMDAwXQ~"}'
}

@test "Import of sd-jwt from section A.3" {
    cat <<EOF | save_asset 'testVector.json'
{   "Alice":{
    "es256_public_key":"b28d4MwZMjw8+00CG4xfnn9SLMVMM19SlqZpVb/uNtRe/nNbC6hpOB1LqFXjfIjqAHBOeO6SYVBCcn+QLHOqTw==",
},
   "signed_selective_disclosure": "eyJhbGciOiAiRVMyNTYifQ.eyJfc2QiOiBbIjBuOXl6RlNXdktfQlVIaWFNaG0xMmdockN0VmFockdKNl8ta1pQLXlTcTQiLCAiQ2gtREJjTDNrYjRWYkhJd3Rrbm5aZE5VSHRoRXE5TVpqb0ZkZzZpZGlobyIsICJEVzdnRlZaU3V5cjQyWVNZeDhwOHJWS0VrdEp6SjN1RkltZW5tSkJJbWRzIiwgIkkwMGZjRlVvRFhDdWNwNXl5MnVqcVBzc0RWR2FXTmlVbGlOel9hd0QwZ2MiLCAiWDlNYVBhRldtUVlwZkhFZHl0UmRhY2xuWW9FcnU4RXp0QkVVUXVXT2U0NCIsICJkOHFrZlBkb2UyUFlFOTNkNU1fZ0JMMWdabHBGUktDYzBkMWxhb2RfX3MwIiwgImxJM0wwaHNlQ1JXbVVQZzgyVkNVTl9hMTdzTUxfNjRRZ0E0SkZUWURGREUiLCAicHVNcEdMb0FHUmJjc0FnNTBVWjBoaFFMS0NMNnF6eFNLNDMwNGtCbjNfSSIsICJ6VTQ1MmxrR2JFS2g4WnVIXzhLeDNDVXZuMUY0eTFnWkxxbERUZ1hfOFBrIl0sICJpc3MiOiAiaHR0cHM6Ly9waWQtcHJvdmlkZXIubWVtYmVyc3RhdGUuZXhhbXBsZS5ldSIsICJpYXQiOiAxNTQxNDkzNzI0LCAiZXhwIjogMTg4MzAwMDAwMCwgInR5cGUiOiAiUGVyc29uSWRlbnRpZmljYXRpb25EYXRhIiwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJjbmYiOiB7Imp3ayI6IHsia3R5IjogIkVDIiwgImNydiI6ICJQLTI1NiIsICJ4IjogIlRDQUVSMTladnUzT0hGNGo0VzR2ZlNWb0hJUDFJTGlsRGxzN3ZDZUdlbWMiLCAieSI6ICJaeGppV1diWk1RR0hWV0tWUTRoYlNJaXJzVmZ1ZWNDRTZ0NGpUOUYySFpRIn19fQ.9hyAKjlth_-BLWKYWkzg-oshIAKIauwC-y8w-a2bWyPGnZ8SE9ijvDEPEdddIi2EFJlt76fK-vN2QcMLCrNR7Q~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7InBvc3RhbF9jb2RlIjogIjEyMzQ1IiwgImxvY2FsaXR5IjogIklyZ2VuZHdvIiwgInN0cmVldF9hZGRyZXNzIjogIlNvbm5lbnN0cmFzc2UgMjMiLCAiY291bnRyeV9jb2RlIjogIkRFIn1d~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0~"
}
EOF
    cat <<EOF | zexe testVector.zen testVector.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have a 'signed selective disclosure'
# TODO: verification is broken by sorting table
# When I verify signed selective disclosure 'signed_selective_disclosure' issued by 'Alice' is valid
Then print the 'signed selective disclosure' as 'decoded selective disclosure' 
EOF
    save_output testVector.out.json
    assert_output '{"signed_selective_disclosure":{"disclosures":[["2GLC42sKQveCfGfryNRN9w","first_name","Erika"],["eluV5Og3gSNII8EYnsxA_A","family_name","Mustermann"],["6Ij7tM-a5iVPGboS5tmvVA","DE"],["eI8ZWm9QnKPpNPeNenHdhQ","nationalities",[{"...":"JuL32QXDzizl-L6CLrfxfjpZsX3O6vsfpCVd1jkwJYg"}]],["Qg_O64zqAxe412a108iroA","birth_family_name","Schmidt"],["AJx-095VPrpTtN4QMOqROA","birthdate","1973-01-01"],["Pc33JM2LchcU_lHggv_ufQ","address",{"country_code":"DE","locality":"Irgendwo","postal_code":"12345","street_address":"Sonnenstrasse 23"}],["G02NSrQfjFXQ7Io09syajA","is_over_18",true],["lklxF5jMYlGTPUovMNIvCA","is_over_21",true],["nPuoQnkRFq3BIeAm7AnXFA","is_over_65",false]],"jwt":{"header":{"alg":"ES256"},"payload":{"_sd":["0n9yzFSWvK_BUHiaMhm12ghrCtVahrGJ6_-kZP-ySq4","Ch-DBcL3kb4VbHIwtknnZdNUHthEq9MZjoFdg6idiho","DW7gFVZSuyr42YSYx8p8rVKEktJzJ3uFImenmJBImds","I00fcFUoDXCucp5yy2ujqPssDVGaWNiUliNz_awD0gc","X9MaPaFWmQYpfHEdytRdaclnYoEru8EztBEUQuWOe44","d8qkfPdoe2PYE93d5M_gBL1gZlpFRKCc0d1laod__s0","lI3L0hseCRWmUPg82VCUN_a17sML_64QgA4JFTYDFDE","puMpGLoAGRbcsAg50UZ0hhQLKCL6qzxSK4304kBn3_I","zU452lkGbEKh8ZuH_8Kx3CUvn1F4y1gZLqlDTgX_8Pk"],"_sd_alg":"sha-256","cnf":{"jwk":{"crv":"P-256","kty":"EC","x":"TCAER19Zvu3OHF4j4W4vfSVoHIP1ILilDls7vCeGemc","y":"ZxjiWWbZMQGHVWKVQ4hbSIirsVfuecCE6t4jT9F2HZQ"}},"exp":1883000000,"iat":1541493724,"iss":"https://pid-provider.memberstate.example.eu","type":"PersonIdentificationData"},"signature":"9hyAKjlth_-BLWKYWkzg-oshIAKIauwC-y8w-a2bWyPGnZ8SE9ijvDEPEdddIi2EFJlt76fK-vN2QcMLCrNR7Q"}}}'
}

@test "Test vector from A.3" {
    cat <<EOF | zexe create_sdjwt_test.zen testVector.out.json
Scenario 'sd_jwt'

Given I have a 'decoded selective disclosure' named 'signed selective disclosure'
Then print the 'signed selective disclosure' as 'signed selective disclosure'
EOF
    save_output testSdJwt.out.json
    assert_output '{"signed_selective_disclosure":"eyJhbGciOiAiRVMyNTYifQ.eyJfc2QiOiBbIjBuOXl6RlNXdktfQlVIaWFNaG0xMmdockN0VmFockdKNl8ta1pQLXlTcTQiLCAiQ2gtREJjTDNrYjRWYkhJd3Rrbm5aZE5VSHRoRXE5TVpqb0ZkZzZpZGlobyIsICJEVzdnRlZaU3V5cjQyWVNZeDhwOHJWS0VrdEp6SjN1RkltZW5tSkJJbWRzIiwgIkkwMGZjRlVvRFhDdWNwNXl5MnVqcVBzc0RWR2FXTmlVbGlOel9hd0QwZ2MiLCAiWDlNYVBhRldtUVlwZkhFZHl0UmRhY2xuWW9FcnU4RXp0QkVVUXVXT2U0NCIsICJkOHFrZlBkb2UyUFlFOTNkNU1fZ0JMMWdabHBGUktDYzBkMWxhb2RfX3MwIiwgImxJM0wwaHNlQ1JXbVVQZzgyVkNVTl9hMTdzTUxfNjRRZ0E0SkZUWURGREUiLCAicHVNcEdMb0FHUmJjc0FnNTBVWjBoaFFMS0NMNnF6eFNLNDMwNGtCbjNfSSIsICJ6VTQ1MmxrR2JFS2g4WnVIXzhLeDNDVXZuMUY0eTFnWkxxbERUZ1hfOFBrIl0sICJfc2RfYWxnIjogInNoYS0yNTYiLCAiY25mIjogeyJqd2siOiB7ImNydiI6ICJQLTI1NiIsICJrdHkiOiAiRUMiLCAieCI6ICJUQ0FFUjE5WnZ1M09IRjRqNFc0dmZTVm9ISVAxSUxpbERsczd2Q2VHZW1jIiwgInkiOiAiWnhqaVdXYlpNUUdIVldLVlE0aGJTSWlyc1ZmdWVjQ0U2dDRqVDlGMkhaUSJ9fSwgImV4cCI6IDE4ODMwMDAwMDAsICJpYXQiOiAxNTQxNDkzNzI0LCAiaXNzIjogImh0dHBzOi8vcGlkLXByb3ZpZGVyLm1lbWJlcnN0YXRlLmV4YW1wbGUuZXUiLCAidHlwZSI6ICJQZXJzb25JZGVudGlmaWNhdGlvbkRhdGEifQ.9hyAKjlth_-BLWKYWkzg-oshIAKIauwC-y8w-a2bWyPGnZ8SE9ijvDEPEdddIi2EFJlt76fK-vN2QcMLCrNR7Q~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7ImNvdW50cnlfY29kZSI6ICJERSIsICJsb2NhbGl0eSI6ICJJcmdlbmR3byIsICJwb3N0YWxfY29kZSI6ICIxMjM0NSIsICJzdHJlZXRfYWRkcmVzcyI6ICJTb25uZW5zdHJhc3NlIDIzIn1d~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0~"}'
   # The above solution is the encoding of the dict in alphabetical order
   # Below the solution given in section A.3 of https://www.rfc-editor.org/rfc/rfc7515.html
   # assert_output '{"signed_selective_disclosure":"eyJhbGciOiAiRVMyNTYifQ.eyJfc2QiOiBbIjBuOXl6RlNXdktfQlVIaWFNaG0xMmdockN0VmFockdKNl8ta1pQLXlTcTQiLCAiQ2gtREJjTDNrYjRWYkhJd3Rrbm5aZE5VSHRoRXE5TVpqb0ZkZzZpZGlobyIsICJEVzdnRlZaU3V5cjQyWVNZeDhwOHJWS0VrdEp6SjN1RkltZW5tSkJJbWRzIiwgIkkwMGZjRlVvRFhDdWNwNXl5MnVqcVBzc0RWR2FXTmlVbGlOel9hd0QwZ2MiLCAiWDlNYVBhRldtUVlwZkhFZHl0UmRhY2xuWW9FcnU4RXp0QkVVUXVXT2U0NCIsICJkOHFrZlBkb2UyUFlFOTNkNU1fZ0JMMWdabHBGUktDYzBkMWxhb2RfX3MwIiwgImxJM0wwaHNlQ1JXbVVQZzgyVkNVTl9hMTdzTUxfNjRRZ0E0SkZUWURGREUiLCAicHVNcEdMb0FHUmJjc0FnNTBVWjBoaFFMS0NMNnF6eFNLNDMwNGtCbjNfSSIsICJ6VTQ1MmxrR2JFS2g4WnVIXzhLeDNDVXZuMUY0eTFnWkxxbERUZ1hfOFBrIl0sICJpc3MiOiAiaHR0cHM6Ly9waWQtcHJvdmlkZXIubWVtYmVyc3RhdGUuZXhhbXBsZS5ldSIsICJpYXQiOiAxNTQxNDkzNzI0LCAiZXhwIjogMTg4MzAwMDAwMCwgInR5cGUiOiAiUGVyc29uSWRlbnRpZmljYXRpb25EYXRhIiwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJjbmYiOiB7Imp3ayI6IHsia3R5IjogIkVDIiwgImNydiI6ICJQLTI1NiIsICJ4IjogIlRDQUVSMTladnUzT0hGNGo0VzR2ZlNWb0hJUDFJTGlsRGxzN3ZDZUdlbWMiLCAieSI6ICJaeGppV1diWk1RR0hWV0tWUTRoYlNJaXJzVmZ1ZWNDRTZ0NGpUOUYySFpRIn19fQ.9hyAKjlth_-BLWKYWkzg-oshIAKIauwC-y8w-a2bWyPGnZ8SE9ijvDEPEdddIi2EFJlt76fK-vN2QcMLCrNR7Q~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7InBvc3RhbF9jb2RlIjogIjEyMzQ1IiwgImxvY2FsaXR5IjogIklyZ2VuZHdvIiwgInN0cmVldF9hZGRyZXNzIjogIlNvbm5lbnN0cmFzc2UgMjMiLCAiY291bnRyeV9jb2RlIjogIkRFIn1d~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0~"}'
}
@test "Create SD_JWT from test vector A.3" {
    cat <<EOF | save_asset test.A3.data.json
{   
    "The Issuer": {
        "es256_public_key":"b28d4MwZMjw8+00CG4xfnn9SLMVMM19SlqZpVb/uNtRe/nNbC6hpOB1LqFXjfIjqAHBOeO6SYVBCcn+QLHOqTw==",
        "keyring":{"es256":"Ur2bNKuBPOrAaxsRnbSH6hIhmNTxSGXshDSUD1a1y7g="}
    },
      "selective_disclosure": {
        "disclosures": [
            ["2GLC42sKQveCfGfryNRN9w", "first_name", "Erika"],
            ["eluV5Og3gSNII8EYnsxA_A", "family_name", "Mustermann"],
            ["6Ij7tM-a5iVPGboS5tmvVA", "DE"],
            ["eI8ZWm9QnKPpNPeNenHdhQ", "nationalities", [{"...": "JuL32QXDzizl-L6CLrfxfjpZsX3O6vsfpCVd1jkwJYg"}]],
            ["Qg_O64zqAxe412a108iroA", "birth_family_name", "Schmidt"],
            ["AJx-095VPrpTtN4QMOqROA", "birthdate", "1973-01-01"],
            ["Pc33JM2LchcU_lHggv_ufQ", "address", {"postal_code":"12345", "locality": "Irgendwo", "street_address": "Sonnenstrasse 23", "country_code": "DE"}],
            ["G02NSrQfjFXQ7Io09syajA", "is_over_18", true],
            ["lklxF5jMYlGTPUovMNIvCA", "is_over_21", true],
            ["nPuoQnkRFq3BIeAm7AnXFA", "is_over_65", false]
        ],
        "payload": {
            "_sd": [
                "0n9yzFSWvK_BUHiaMhm12ghrCtVahrGJ6_-kZP-ySq4",
                "Ch-DBcL3kb4VbHIwtknnZdNUHthEq9MZjoFdg6idiho",
                "DW7gFVZSuyr42YSYx8p8rVKEktJzJ3uFImenmJBImds",
                "I00fcFUoDXCucp5yy2ujqPssDVGaWNiUliNz_awD0gc",
                "X9MaPaFWmQYpfHEdytRdaclnYoEru8EztBEUQuWOe44",
                "d8qkfPdoe2PYE93d5M_gBL1gZlpFRKCc0d1laod__s0",
                "lI3L0hseCRWmUPg82VCUN_a17sML_64QgA4JFTYDFDE",
                "puMpGLoAGRbcsAg50UZ0hhQLKCL6qzxSK4304kBn3_I",
                "zU452lkGbEKh8ZuH_8Kx3CUvn1F4y1gZLqlDTgX_8Pk"
            ],
            "iss": "https://pid-provider.memberstate.example.eu",
            "iat": 1541493724,
            "exp": 1883000000,
            "vct": "PersonIdentificationData",
            "_sd_alg": "sha-256",
            "cnf": {
                "jwk": {
                    "kty": "EC",
                    "crv": "P-256",
                    "x": "TCAER19Zvu3OHF4j4W4vfSVoHIP1ILilDls7vCeGemc",
                    "y": "ZxjiWWbZMQGHVWKVQ4hbSIirsVfuecCE6t4jT9F2HZQ"
                }
            }
        }
    }
}
EOF
    cat <<EOF | zexe test_A3.zen test.A3.data.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'The Issuer'
and I have my 'keyring'

Given I have 'selective_disclosure'

When I create the signed selective disclosure of 'selective_disclosure'

Then print the 'signed selective disclosure'


EOF
    save_output test_A3.out.json
    assert_output '{"signed_selective_disclosure":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbIjBuOXl6RlNXdktfQlVIaWFNaG0xMmdockN0VmFockdKNl8ta1pQLXlTcTQiLCAiQ2gtREJjTDNrYjRWYkhJd3Rrbm5aZE5VSHRoRXE5TVpqb0ZkZzZpZGlobyIsICJEVzdnRlZaU3V5cjQyWVNZeDhwOHJWS0VrdEp6SjN1RkltZW5tSkJJbWRzIiwgIkkwMGZjRlVvRFhDdWNwNXl5MnVqcVBzc0RWR2FXTmlVbGlOel9hd0QwZ2MiLCAiWDlNYVBhRldtUVlwZkhFZHl0UmRhY2xuWW9FcnU4RXp0QkVVUXVXT2U0NCIsICJkOHFrZlBkb2UyUFlFOTNkNU1fZ0JMMWdabHBGUktDYzBkMWxhb2RfX3MwIiwgImxJM0wwaHNlQ1JXbVVQZzgyVkNVTl9hMTdzTUxfNjRRZ0E0SkZUWURGREUiLCAicHVNcEdMb0FHUmJjc0FnNTBVWjBoaFFMS0NMNnF6eFNLNDMwNGtCbjNfSSIsICJ6VTQ1MmxrR2JFS2g4WnVIXzhLeDNDVXZuMUY0eTFnWkxxbERUZ1hfOFBrIl0sICJfc2RfYWxnIjogInNoYS0yNTYiLCAiY25mIjogeyJqd2siOiB7ImNydiI6ICJQLTI1NiIsICJrdHkiOiAiRUMiLCAieCI6ICJUQ0FFUjE5WnZ1M09IRjRqNFc0dmZTVm9ISVAxSUxpbERsczd2Q2VHZW1jIiwgInkiOiAiWnhqaVdXYlpNUUdIVldLVlE0aGJTSWlyc1ZmdWVjQ0U2dDRqVDlGMkhaUSJ9fSwgImV4cCI6IDE4ODMwMDAwMDAsICJpYXQiOiAxNTQxNDkzNzI0LCAiaXNzIjogImh0dHBzOi8vcGlkLXByb3ZpZGVyLm1lbWJlcnN0YXRlLmV4YW1wbGUuZXUiLCAidmN0IjogIlBlcnNvbklkZW50aWZpY2F0aW9uRGF0YSJ9.gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39saxeyzVATniAdMmanPdAkHCo1NDslnJfFvO5iIuMIzys5w~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7ImNvdW50cnlfY29kZSI6ICJERSIsICJsb2NhbGl0eSI6ICJJcmdlbmR3byIsICJwb3N0YWxfY29kZSI6ICIxMjM0NSIsICJzdHJlZXRfYWRkcmVzcyI6ICJTb25uZW5zdHJhc3NlIDIzIn1d~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0~"}'

    #the output should be the following:
    #assert_output '{"signed_selective_disclosure": "eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbIjBuOXl6RlNXdktfQlVIaWFNaG0xMmdockN0VmFockdKNl8ta1pQLXlTcTQiLCAiQ2gtREJjTDNrYjRWYkhJd3Rrbm5aZE5VSHRoRXE5TVpqb0ZkZzZpZGlobyIsICJEVzdnRlZaU3V5cjQyWVNZeDhwOHJWS0VrdEp6SjN1RkltZW5tSkJJbWRzIiwgIkkwMGZjRlVvRFhDdWNwNXl5MnVqcVBzc0RWR2FXTmlVbGlOel9hd0QwZ2MiLCAiWDlNYVBhRldtUVlwZkhFZHl0UmRhY2xuWW9FcnU4RXp0QkVVUXVXT2U0NCIsICJkOHFrZlBkb2UyUFlFOTNkNU1fZ0JMMWdabHBGUktDYzBkMWxhb2RfX3MwIiwgImxJM0wwaHNlQ1JXbVVQZzgyVkNVTl9hMTdzTUxfNjRRZ0E0SkZUWURGREUiLCAicHVNcEdMb0FHUmJjc0FnNTBVWjBoaFFMS0NMNnF6eFNLNDMwNGtCbjNfSSIsICJ6VTQ1MmxrR2JFS2g4WnVIXzhLeDNDVXZuMUY0eTFnWkxxbERUZ1hfOFBrIl0sICJpc3MiOiAiaHR0cHM6Ly9waWQtcHJvdmlkZXIubWVtYmVyc3RhdGUuZXhhbXBsZS5ldSIsICJpYXQiOiAxNTQxNDkzNzI0LCAiZXhwIjogMTg4MzAwMDAwMCwgInZjdCI6ICJQZXJzb25JZGVudGlmaWNhdGlvbkRhdGEiLCAiX3NkX2FsZyI6ICJzaGEtMjU2IiwgImNuZiI6IHsiandrIjogeyJrdHkiOiAiRUMiLCAiY3J2IjogIlAtMjU2IiwgIngiOiAiVENBRVIxOVp2dTNPSEY0ajRXNHZmU1ZvSElQMUlMaWxEbHM3dkNlR2VtYyIsICJ5IjogIlp4amlXV2JaTVFHSFZXS1ZRNGhiU0lpcnNWZnVlY0NFNnQ0alQ5RjJIWlEifX19.VStKGOA5TdLsrjahM4dRfDrbsy7BmrUNGw3jaBuxZnHYvmS2EnQ-ib7zSCUVBGGbcyORDFCMd_F6gr8CM9N3WQ~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7InBvc3RhbF9jb2RlIjogIjEyMzQ1IiwgImxvY2FsaXR5IjogIklyZ2VuZHdvIiwgInN0cmVldF9hZGRyZXNzIjogIlNvbm5lbnN0cmFzc2UgMjMiLCAiY291bnRyeV9jb2RlIjogIkRFIn1d~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0~"}'
    #test vector from App. A.3 of https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-07.txt
    #issuer key from https://github.com/oauth-wg/oauth-selective-disclosure-jwt/blob/master/examples/settings.yml
}

@test "create table of disclosed kv" {
    cat <<EOF | zexe create_disclosed_kv.zen test_A3.out.json
Scenario 'sd_jwt'

Given I have 'signed_selective_disclosure'

When I create the disclosed kv from signed selective disclosure 'signed_selective_disclosure'

Then print the 'disclosed kv'

EOF
    save_output create_disclosed_kv.out.json
    assert_output '{"disclosed_kv":{"address":{"country_code":"DE","locality":"Irgendwo","postal_code":"12345","street_address":"Sonnenstrasse 23"},"birth_family_name":"Schmidt","birthdate":"1973-01-01","family_name":"Mustermann","first_name":"Erika","is_over_18":true,"is_over_21":true,"is_over_65":false,"nationalities":[{"...":"JuL32QXDzizl-L6CLrfxfjpZsX3O6vsfpCVd1jkwJYg"}]}}'
}
