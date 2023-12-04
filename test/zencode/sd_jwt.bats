load ../bats_setup
load ../bats_zencode
SUBDOC=sd_jwt

@test "Import metadata" {
    cat <<EOF | save_asset metadata.keys.json
{"supported_selective_disclosure":{"authorization_endpoint":"http://issuer.example.org/authorize","authorization_response_iss_parameter_supported":true,"claim_types_supported":["normal"],"claims_parameter_supported":false,"code_challenge_methods_supported":["S256"],"credential_endpoint":"http://issuer.example.org/credentials","credential_issuer":"http://issuer.example.org","credentials_supported":[{"credentialSubject":{"family_name":{"display":[{"locale":"en-US","name":"Family Name"}]},"given_name":{"display":[{"locale":"en-US","name":"Given Name"}]}},"cryptographic_binding_methods_supported":["did:jwk"],"cryptographic_suites_supported":["ES256"],"display":[{"background_color":"#000000","locale":"en-US","name":"IdentityCredential","text_color":"#ffffff"}],"format":"vc+sd-jwt","id":"ab8c936e-b9ab-4cf5-9862-c3a25bb82996","order":["given_name","family_name"],"types":["VerifiableCredential","IdentityCredential"]}],"grant_types_supported":["authorization_code","urn:ietf:params:oauth:grant-type:pre-authorized_code"],"id_token_signing_alg_values_supported":["ES256"],"issuer":"http://issuer.example.org","jwks_uri":"http://issuer.example.org/jwks","pushed_authorization_request_endpoint":"http://issuer.example.org/par","request_object_signing_alg_values_supported":["ES256"],"request_parameter_supported":true,"request_uri_parameter_supported":true,"response_modes_supported":["query"],"response_types_supported":["code"],"scopes_supported":["openid","IdentityCredential"],"subject_types_supported":["public"],"token_endpoint":"http://issuer.example.org/token","token_endpoint_auth_methods_supported":["none"]}}
EOF
    cat <<EOF | zexe metadata.zen metadata.keys.json
Scenario 'sd_jwt': sign JSON
Given I have a 'supported selective disclosure'
and debug
Then print data
EOF
    save_output 'metadata.out.json'
    assert_output "$(cat metadata.keys.json)"
}

@test "Import metadata and add" {
    cat <<EOF | save_asset metadata2.keys.json
{
    "supported_selective_disclosure":{"authorization_endpoint":"http://issuer.example.org/authorize","authorization_response_iss_parameter_supported":true,"claim_types_supported":["normal"],"claims_parameter_supported":false,"code_challenge_methods_supported":["S256"],"credential_endpoint":"http://issuer.example.org/credentials","credential_issuer":"http://issuer.example.org","credentials_supported":[{"credentialSubject":{"family_name":{"display":[{"locale":"en-US","name":"Family Name"}]},"given_name":{"display":[{"locale":"en-US","name":"Given Name"}]}},"cryptographic_binding_methods_supported":["did:jwk"],"cryptographic_suites_supported":["ES256"],"display":[{"background_color":"#000000","locale":"en-US","name":"IdentityCredential","text_color":"#ffffff"}],"format":"vc+sd-jwt","id":"ab8c936e-b9ab-4cf5-9862-c3a25bb82996","order":["given_name","family_name"],"types":["VerifiableCredential","IdentityCredential"]}],"grant_types_supported":["authorization_code","urn:ietf:params:oauth:grant-type:pre-authorized_code"],"id_token_signing_alg_values_supported":["ES256"],"issuer":"http://issuer.example.org","jwks_uri":"http://issuer.example.org/jwks","pushed_authorization_request_endpoint":"http://issuer.example.org/par","request_object_signing_alg_values_supported":["ES256"],"request_parameter_supported":true,"request_uri_parameter_supported":true,"response_modes_supported":["query"],"response_types_supported":["code"],"scopes_supported":["openid","IdentityCredential"],"subject_types_supported":["public"],"token_endpoint":"http://issuer.example.org/token","token_endpoint_auth_methods_supported":["none"]},
        "is_over_18":  {
            "name": "Over 18",
            "locale": "en-US"
        },
        "order_name": "is_over_18",
        "id": "ab8c936e-b9ab-4cf5-9862-c3a25bb82996"
}
EOF
    cat <<EOF | zexe metadata2.zen metadata2.keys.json
Scenario 'sd_jwt': sign JSON
Given I have a 'supported selective disclosure'
Given I have a 'string' named 'id'
Given I have a 'string' named 'order_name'
Given I have a 'string dictionary' named 'is_over_18'
When I use supported selective disclosure to disclose 'is_over_18' named 'order_name' with id 'id'
Then print data
EOF
    save_output 'metadata2.out.json'
    assert_output '{"id":"ab8c936e-b9ab-4cf5-9862-c3a25bb82996","is_over_18":{"locale":"en-US","name":"Over 18"},"order_name":"is_over_18","supported_selective_disclosure":{"authorization_endpoint":"http://issuer.example.org/authorize","authorization_response_iss_parameter_supported":true,"claim_types_supported":["normal"],"claims_parameter_supported":false,"code_challenge_methods_supported":["S256"],"credential_endpoint":"http://issuer.example.org/credentials","credential_issuer":"http://issuer.example.org","credentials_supported":[{"credentialSubject":{"family_name":{"display":[{"locale":"en-US","name":"Family Name"}]},"given_name":{"display":[{"locale":"en-US","name":"Given Name"}]},"is_over_18":{"display":[{"locale":"en-US","name":"Over 18"}]}},"cryptographic_binding_methods_supported":["did:jwk"],"cryptographic_suites_supported":["ES256"],"display":[{"background_color":"#000000","locale":"en-US","name":"IdentityCredential","text_color":"#ffffff"}],"format":"vc+sd-jwt","id":"ab8c936e-b9ab-4cf5-9862-c3a25bb82996","order":["given_name","family_name","is_over_18"],"types":["VerifiableCredential","IdentityCredential"]}],"grant_types_supported":["authorization_code","urn:ietf:params:oauth:grant-type:pre-authorized_code"],"id_token_signing_alg_values_supported":["ES256"],"issuer":"http://issuer.example.org","jwks_uri":"http://issuer.example.org/jwks","pushed_authorization_request_endpoint":"http://issuer.example.org/par","request_object_signing_alg_values_supported":["ES256"],"request_parameter_supported":true,"request_uri_parameter_supported":true,"response_modes_supported":["query"],"response_types_supported":["code"],"scopes_supported":["openid","IdentityCredential"],"subject_types_supported":["public"],"token_endpoint":"http://issuer.example.org/token","token_endpoint_auth_methods_supported":["none"]}}'
}

@test "Create JWK with es256 public key" {
    cat <<EOF | save_asset jwk_es256.json
{
    "Alice": {
        "keyring": {
        "es256": "Y5xo2U3cACj8V+8/mQYLmWb/+A768/ui0tN8+vsu36g="
        }
  },
  "kid": "1Jdpq0-Eu0KnZ4R9mapqSiFQfTVvHFg_SrLYifwz8Fc"
}
EOF
    cat <<EOF | zexe jwk_es256.zen jwk_es256.json
Scenario 'es256'
Scenario 'sd_jwt'

Given I am known as 'Alice'
and I have my 'keyring'
Given I have a 'url64' named 'kid'
When I create the es256 public key

When I create es256 public jwk with 'es256 public key'
When I create the jwt key binding with jwk 'es256 public jwk'

Then print 'es256 public jwk'
Then print 'kid'
Then print 'jwk key binding'
EOF
    save_output jwk_es256_out.json
    assert_output '{"es256_public_jwk":{"alg":"ES256","crv":"P-256","kty":"EC","use":"sig","x":"Z_zRBEUbhtqDzme6kcGbtV3X4BxARVC8ySoC02IbQu8","y":"zXFljZyvxo9cgvCdcJfrmww9HeSiJUFbI98UUwMkPss"},"jwk_key_binding":{"cnf":{"jwk":{"alg":"ES256","crv":"P-256","kty":"EC","use":"sig","x":"Z_zRBEUbhtqDzme6kcGbtV3X4BxARVC8ySoC02IbQu8","y":"zXFljZyvxo9cgvCdcJfrmww9HeSiJUFbI98UUwMkPss"}}},"kid":"1Jdpq0-Eu0KnZ4R9mapqSiFQfTVvHFg_SrLYifwz8Fc"}'
}

@test "Set kid value in JWK with es256 public key" {
    cat <<EOF | zexe jwk_es256_imp.zen jwk_es256_out.json
Scenario 'sd_jwt'

Given I have 'es256 public jwk'
Given I have a 'url64' named 'kid'
Given I have a 'jwk_key_binding'
When I set kid in jwk 'es256 public jwk' to 'kid'
Then print 'es256 public jwk'
Then print 'jwk_key_binding'
EOF
    save_output jwk_es256_imp_out.json
    assert_output '{"es256_public_jwk":{"alg":"ES256","crv":"P-256","kid":"1Jdpq0-Eu0KnZ4R9mapqSiFQfTVvHFg_SrLYifwz8Fc","kty":"EC","use":"sig","x":"Z_zRBEUbhtqDzme6kcGbtV3X4BxARVC8ySoC02IbQu8","y":"zXFljZyvxo9cgvCdcJfrmww9HeSiJUFbI98UUwMkPss"},"jwk_key_binding":{"cnf":{"jwk":{"alg":"ES256","crv":"P-256","kty":"EC","use":"sig","x":"Z_zRBEUbhtqDzme6kcGbtV3X4BxARVC8ySoC02IbQu8","y":"zXFljZyvxo9cgvCdcJfrmww9HeSiJUFbI98UUwMkPss"}}}}'
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
{"object":{"age":42,"degree":"math","family_name":"Lippo","given_name":"Mimmo","iss":"http://example.org","sub":"user 42"}, "id": "ab8c936e-b9ab-4cf5-9862-c3a25bb82996"}
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
    assert_output '{"selective_disclosure_request":{"fields":["given_name","family_name"],"object":{"age":42,"degree":"math","family_name":"Lippo","given_name":"Mimmo","iss":"http://example.org","sub":"user 42"}}}'
}

# TODO: problems updated_at

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
            "phone_number_verified","address","birthdate"
        ],
        "object": {
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

When I create the selective disclosure payload of 'selective_disclosure_request'
When I create the signed selective disclosure of 'selective disclosure payload'
Then print data
Then print the 'keyring'
EOF
    save_output sd_payload.out.json
    assert_output '{"es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==","keyring":{"es256":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="},"selective_disclosure_payload":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"]],"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo"],"_sd_alg":"sha-256","iss":"http://example.org","sub":"user 42"}},"selective_disclosure_request":{"fields":["given_name","family_name","email","phone_number","phone_number_verified","address","birthdate"],"object":{"address":{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"},"birthdate":"1940-01-01","email":"johndoe@example.com","family_name":"Doe","given_name":"John","iss":"http://example.org","nationalities":["US","DE"],"phone_number":"+1-202-555-0101","phone_number_verified":true,"sub":"user 42","updated_at":1.57e+09}},"signed_selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"]],"jwt":{"header":{"alg":"ES256","typ":"JWT"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo"],"_sd_alg":"sha-256","iss":"http://example.org","sub":"user 42"},"signature":"i95SyUjPhs5/PQinx1cHsOHXwbDGlr11ONaXrk13vFLvSo8Dn3rtw7xvcmROsB6LX3q7wFaaFmE3m5t8xTPxOw=="}}}'
}

@test "Import and export SD Payload" {

    cat <<EOF | zexe sd_payload2.zen sd_payload.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I have 'keyring'
Given I have the 'es256 public key'
Given I have 'selective_disclosure_request'
Given I have 'selective_disclosure_payload'
Given I have 'signed selective disclosure'

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

Given I have 'signed selective disclosure'
Given I have a 'string array' named 'some disclosure'

When I create the selective disclosure presentation of 'signed selective disclosure' with disclosures 'some disclosure'

Then print 'selective disclosure presentation'

EOF
    save_output sd_presentation.out.json
    assert_output '{"selective_disclosure_presentation":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"]],"jwt":{"header":{"alg":"ES256","typ":"JWT"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo"],"_sd_alg":"sha-256","iss":"http://example.org","sub":"user 42"},"signature":"i95SyUjPhs5/PQinx1cHsOHXwbDGlr11ONaXrk13vFLvSo8Dn3rtw7xvcmROsB6LX3q7wFaaFmE3m5t8xTPxOw=="}}}'
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
Given I have 'signed selective disclosure'

When I verify sd jwt 'signed_selective_disclosure' issued by 'Alice' is valid

Then print data

EOF
    cat <<EOF | zexe sd_verification.zen alice_es256_keys.json sd_payload2.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have 'signed selective disclosure'

When I verify sd jwt 'signed_selective_disclosure' issued by 'Alice' is valid

Then print data

EOF
    save_output sd_verification.out.json
    assert_output '{"es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==","signed_selective_disclosure":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["5-Y_kvJBo3ni_JNNUrFnIA","family_name","Doe"],["VyJ47aH6-hysFuthAZJP-A","email","johndoe@example.com"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"],["5XsSIXmaZbf5ikQgMSVGjQ","phone_number_verified",true],["br5gmh-cSRNAvocKCmAD0A","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["6UasczRKmme8SOUwelXq2w","birthdate","1940-01-01"]],"jwt":{"header":{"alg":"ES256","typ":"JWT"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo"],"_sd_alg":"sha-256","iss":"http://example.org","sub":"user 42"},"signature":"i95SyUjPhs5/PQinx1cHsOHXwbDGlr11ONaXrk13vFLvSo8Dn3rtw7xvcmROsB6LX3q7wFaaFmE3m5t8xTPxOw=="}}}'
}

@test "Verify selective disclosure presentation" {
    cat <<EOF | zexe ver_presentation.zen alice_es256_keys.json sd_presentation.out.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have 'selective disclosure presentation'

When I verify sd jwt 'selective_disclosure_presentation' issued by 'Alice' is valid

Then print data

EOF
    save_output ver_presentation.out.json
    assert_output '{"es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg==","selective_disclosure_presentation":{"disclosures":[["XdjAYj-RY95-uyYMI8fR3w","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","phone_number","+1-202-555-0101"]],"jwt":{"header":{"alg":"ES256","typ":"JWT"},"payload":{"_sd":["t0Chup62fiaD6Swz_ZYHu4vbhIEOTigVg7z2lyNBKgY","W_VxVKGf1_ncWfAjRoJUGx7YeHRhKzb_ucVhCLU69Dc","PteND5DdwH6yBuxUKD3kpSTWUNZiDNICxMw3l9LXJQ8","wpyUw7kDDETJfMnnbB74VnolcTIw1acFDpQiAnGUwqQ","qdN_67i12h1IuvARQq67rCWxd-uPIA98HRjaiq2HywM","mFtFOS4Z2ciGRZpsAfsSR7GLi_qb3IFbiQShE9DwRUY","nBZt3hAqBI5CPUJREzMlXdZh6triTkWs2dsSXTfLzlo"],"_sd_alg":"sha-256","iss":"http://example.org","sub":"user 42"},"signature":"i95SyUjPhs5/PQinx1cHsOHXwbDGlr11ONaXrk13vFLvSo8Dn3rtw7xvcmROsB6LX3q7wFaaFmE3m5t8xTPxOw=="}}}'
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
            "signature":"zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4+Ai8uCNZgm+KpfpBANXo5NB2x2oWjqiWA=="
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
        "disclosures":[["VyJ47aH6-hysFuthAZJP-A","given_name","John"],["vIXGZmzovnpG7Q_4mUJsOw","family_name","Doe"],["5XsSIXmaZbf5ikQgMSVGjQ","email","johndoe@example.com"],["br5gmh-cSRNAvocKCmAD0A","phone_number","+1-202-555-0101"],["6UasczRKmme8SOUwelXq2w","phone_number_verified"],["Ll27jjwT4yzd0i-7NGdZAw","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["DR92VSF2l3Az1K1-LyWO1w","birthdate","1940-01-01"]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["cMZilhOF9uEyvW_vCKx8IkbqfmntjqkV8HCFQ_lgPq0","DjUC3iXDmUj0QQgbZM7PQhhOLI3EjqSNzz3IhCpqQhg","wyoSepSkpJXnOxKlsypeqjr9PMFXf024GlIBPgVKnrg","MW58zqUyooJw5zGmASCETNi4qORcewuTRWDhLMLavis","sftnu87bkbl62AB38gmuyQdX5yD95TxMuzhvyiD7Wb8","dydbjYL8bcTkcXtLZ2e8514B7n7QDnOgOWD5Fniwjdo","84Vp4ymg-8VScgYletGB4TfHboLPkIXLaP3djL2Km0U"],
                        "_sd_alg":"sha-256",
                        "iss":"http://example.org",
                        "sub":"user 42"
                    },
            "signature":"zFjnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4+Ai8uCNZgm+KpfpBANXo5NB2x2oWjqiWA=="
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
            "signature":"zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4+Ai8uCNZgm+KpfpBANXo5NB2x2oWjqiWA=="
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
        "disclosures":[["VyJ47aH6-hysFuthAZJP-A","given_name","Paolo"],["vIXGZmzovnpG7Q_4mUJsOw","family_name","Doe"],["5XsSIXmaZbf5ikQgMSVGjQ","email","johndoe@example.com"],["br5gmh-cSRNAvocKCmAD0A","phone_number","+1-202-555-0101"],["6UasczRKmme8SOUwelXq2w","phone_number_verified",true],["Ll27jjwT4yzd0i-7NGdZAw","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["DR92VSF2l3Az1K1-LyWO1w","birthdate","1940-01-01"]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["cMZilhOF9uEyvW_vCKx8IkbqfmntjqkV8HCFQ_lgPq0","DjUC3iXDmUj0QQgbZM7PQhhOLI3EjqSNzz3IhCpqQhg","wyoSepSkpJXnOxKlsypeqjr9PMFXf024GlIBPgVKnrg","MW58zqUyooJw5zGmASCETNi4qORcewuTRWDhLMLavis","sftnu87bkbl62AB38gmuyQdX5yD95TxMuzhvyiD7Wb8","dydbjYL8bcTkcXtLZ2e8514B7n7QDnOgOWD5Fniwjdo","84Vp4ymg-8VScgYletGB4TfHboLPkIXLaP3djL2Km0U"],
                        "_sd_alg":"sha-256",
                        "iss":"http://example.org",
                        "sub":"user 42"
                    },
            "signature":"zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4+Ai8uCNZgm+KpfpBANXo5NB2x2oWjqiWA=="
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
        "disclosures":[["VyJ47aH6-hysFuthAZJP-A","iss","John"],["vIXGZmzovnpG7Q_4mUJsOw","family_name","Doe"],["5XsSIXmaZbf5ikQgMSVGjQ","email","johndoe@example.com"],["br5gmh-cSRNAvocKCmAD0A","phone_number","+1-202-555-0101"],["6UasczRKmme8SOUwelXq2w","phone_number_verified",true],["Ll27jjwT4yzd0i-7NGdZAw","address",{"country":"US","locality":"Anytown","region":"Anystate","street_address":"123 Main St"}],["DR92VSF2l3Az1K1-LyWO1w","birthdate","1940-01-01"]],
        "jwt":{
            "header":{"alg":"ES256","typ":"JWT"},
            "payload":{"_sd":["cMZilhOF9uEyvW_vCKx8IkbqfmntjqkV8HCFQ_lgPq0","DjUC3iXDmUj0QQgbZM7PQhhOLI3EjqSNzz3IhCpqQhg","wyoSepSkpJXnOxKlsypeqjr9PMFXf024GlIBPgVKnrg","MW58zqUyooJw5zGmASCETNi4qORcewuTRWDhLMLavis","sftnu87bkbl62AB38gmuyQdX5yD95TxMuzhvyiD7Wb8","dydbjYL8bcTkcXtLZ2e8514B7n7QDnOgOWD5Fniwjdo","84Vp4ymg-8VScgYletGB4TfHboLPkIXLaP3djL2Km0U"],
                        "_sd_alg":"sha-256",
                        "iss":"http://example.org",
                        "sub":"user 42"
                    },
            "signature":"zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4+Ai8uCNZgm+KpfpBANXo5NB2x2oWjqiWA=="
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

Given I have a 'sd jwt' named 'signed selective disclosure'
Then print the 'signed selective disclosure' as 'sd jwt'
EOF
    save_output sd_jwt_encoded.out.json
    assert_output "$(cat sd-jwt.data.json)"
}

@test "Verify SD JWT encoded" {
        cat <<EOF | save_asset 'ver-sd-jwt.data.json'
{   "Alice": {
        "es256_public_key":"gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39sawziR3I49jMp/6ChAupQYqZhYPVC/RtxBI+tUcULh1SCg=="
    },
    "signed_selective_disclosure":"eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJfc2QiOlsiY01aaWxoT0Y5dUV5dldfdkNLeDhJa2JxZm1udGpxa1Y4SENGUV9sZ1BxMCIsIkRqVUMzaVhEbVVqMFFRZ2JaTTdQUWhoT0xJM0VqcVNOenozSWhDcHFRaGciLCJ3eW9TZXBTa3BKWG5PeEtsc3lwZXFqcjlQTUZYZjAyNEdsSUJQZ1ZLbnJnIiwiTVc1OHpxVXlvb0p3NXpHbUFTQ0VUTmk0cU9SY2V3dVRSV0RoTE1MYXZpcyIsInNmdG51ODdia2JsNjJBQjM4Z211eVFkWDV5RDk1VHhNdXpodnlpRDdXYjgiLCJkeWRiallMOGJjVGtjWHRMWjJlODUxNEI3bjdRRG5PZ09XRDVGbml3amRvIiwiODRWcDR5bWctOFZTY2dZbGV0R0I0VGZIYm9MUGtJWExhUDNkakwyS20wVSJdLCJfc2RfYWxnIjoic2hhLTI1NiIsImlzcyI6Imh0dHA6Ly9leGFtcGxlLm9yZyIsInN1YiI6InVzZXIgNDIifQ.zfJnEY9fHtkPtOL0b97DCa7zjV5h13Yazxolw9sfZrcFax8G7xSG4-Ai8uCNZgm-KpfpBANXo5NB2x2oWjqiWA~WyJWeUo0N2FINi1oeXNGdXRoQVpKUC1BIiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyJ2SVhHWm16b3ZucEc3UV80bVVKc093IiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyI1WHNTSVhtYVpiZjVpa1FnTVNWR2pRIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~WyJicjVnbWgtY1NSTkF2b2NLQ21BRDBBIiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ~WyI2VWFzY3pSS21tZThTT1V3ZWxYcTJ3IiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd~WyJMbDI3amp3VDR5emQwaS03TkdkWkF3IiwgImFkZHJlc3MiLCB7ImNvdW50cnkiOiAiVVMiLCAibG9jYWxpdHkiOiAiQW55dG93biIsICJyZWdpb24iOiAiQW55c3RhdGUiLCAic3RyZWV0X2FkZHJlc3MiOiAiMTIzIE1haW4gU3QifV0~WyJEUjkyVlNGMmwzQXoxSzEtTHlXTzF3IiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0~"}
EOF
    cat <<EOF | zexe verify_sd_jwt_encoded ver-sd-jwt.data.json
Scenario 'sd_jwt'
Scenario 'es256'

Given I am known as 'Alice'
Given I have my 'es256 public key'
Given I have a 'sd jwt' named 'signed selective disclosure'
When I verify sd jwt 'signed_selective_disclosure' issued by 'Alice' is valid
Then print the 'signed selective disclosure' as 'sd jwt'
EOF
    save_output verify_sd_jwt_encoded.out.json
    assert_output "$(cat sd-jwt.data.json)"
}
