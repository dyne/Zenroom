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
{"selective_disclosure_request":{"fields":["given_name","age","family_name"],"object":{"age":42,"degree":"math","family_name":"Lippo","given_name":"Mimmo"}}}
EOF
    cat <<EOF | zexe valid_sdr.zen valid_sdr.data.json
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
Then print data
EOF
    save_output valid_sdr.out.json
    assert_output "$(cat valid_sdr.data.json)"
}

@test "Fail import SDR for using restricted claim" {
    cat <<EOF | save_asset invalid_sdr.data.json
{"selective_disclosure_request":{"fields":["given_name","age"],"object":{"iat":42,"family_name":"Lippo","given_name":"Mimmo"}}}
EOF
    cat <<EOF | save_asset invalid_sdr.zen
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
Then print data
EOF
    run $ZENROOM_EXECUTABLE -z -a invalid_sdr.data.json invalid_sdr.zen
    assert_line --partial 'SD request can not contain a claim with key'
}

@test "Fail import SDR for disclosing claim not in object" {
    cat <<EOF | save_asset invalid_sdr2.data.json
{"selective_disclosure_request":{"fields":["given_name","age","address"],"object":{"age":42,"family_name":"Lippo","given_name":"Mimmo"}}}
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

@test "SDR matches SSD" {
    cat <<EOF | zexe sdr_matches_ssd.zen valid_sdr.data.json metadata.keys.json
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
Given I have 'supported_selective_disclosure'
When I verify the 'selective_disclosure_request' matches 'supported selective disclosure'
Then print the string 'ok'
EOF
    save_output sdr_matches_ssd.out.json
    assert_output '{"output":["ok"]}'
}

@test "SDR doesn't match SSD" {
    cat <<EOF | zexe sdr_does_not_match_ssd.zen valid_sdr.data.json metadata2.out.json
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
Given I have 'supported_selective_disclosure'
If I verify the 'selective_disclosure_request' matches 'supported selective disclosure'
Then print the string 'failed'
endif
EOF
    save_output sdr_matches_ssd.out.json
    assert_output '[]'
}

# TODO: problems sub, updated_at

@test "Create SD Payload" {
    cat <<EOF | save_asset sd_payload.data.json
{
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
            ]
        }
    }
}
EOF
    cat <<EOF | zexe sd_payload.zen sd_payload.data.json
Scenario 'sd_jwt'

Given I have 'selective_disclosure_request'
When I create the selective disclosure payload of 'selective_disclosure_request'
Then print data
EOF
    save_output sd_payload.out.json
    assert_output '[]'
}

@test "Import SD Payload" {

    cat <<EOF | zexe sd_payload2.zen sd_payload.out.json
Scenario 'sd_jwt'

Given I have 'selective_disclosure_payload'

Then print data
EOF
    save_output sd_payload2.out.json
    assert_output '[]'
}
