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

