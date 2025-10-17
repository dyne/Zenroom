load ../bats_setup
load ../bats_zencode
SUBDOC=dcql

@test "DCQL: validate dcql_query structure" {
    # examples from https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#appendix-D
    cat << EOF | save_asset example_dcql_query.data.json
{
    "D1":{
        "credentials":[
            {
                "id":"my_credential",
                "format":"mso_mdoc",
                "meta":{
                    "doctype_value":"org.iso.7367.1.mVRC"
                },
                "claims":[
                    {
                        "path":[
                            "org.iso.7367.1",
                            "vehicle_holder"
                        ]
                    },
                    {
                        "path":[
                            "org.iso.18013.5.1",
                            "first_name"
                        ]
                    }
                ]
            }
        ]
    },
    "D2":{
        "credentials":[
            {
                "id":"pid",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://credentials.example.com/identity_credential"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "given_name"
                        ]
                    },
                    {
                        "path":[
                            "family_name"
                        ]
                    },
                    {
                        "path":[
                            "address",
                            "street_address"
                        ]
                    }
                ]
            },
            {
                "id":"mdl",
                "format":"mso_mdoc",
                "meta":{
                    "doctype_value":"org.iso.7367.1.mVRC"
                },
                "claims":[
                    {
                        "path":[
                            "org.iso.7367.1",
                            "vehicle_holder"
                        ]
                    },
                    {
                        "path":[
                            "org.iso.18013.5.1",
                            "first_name"
                        ]
                    }
                ]
            }
        ]
    },
    "D3":{
        "credentials":[
            {
                "id":"pid",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://credentials.example.com/identity_credential"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "given_name"
                        ]
                    },
                    {
                        "path":[
                            "family_name"
                        ]
                    },
                    {
                        "path":[
                            "address",
                            "street_address"
                        ]
                    }
                ]
            },
            {
                "id":"other_pid",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://othercredentials.example/pid"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "given_name"
                        ]
                    },
                    {
                        "path":[
                            "family_name"
                        ]
                    },
                    {
                        "path":[
                            "address",
                            "street_address"
                        ]
                    }
                ]
            },
            {
                "id":"pid_reduced_cred_1",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://credentials.example.com/reduced_identity_credential"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "family_name"
                        ]
                    },
                    {
                        "path":[
                            "given_name"
                        ]
                    }
                ]
            },
            {
                "id":"pid_reduced_cred_2",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://cred.example/residence_credential"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "postal_code"
                        ]
                    },
                    {
                        "path":[
                            "locality"
                        ]
                    },
                    {
                        "path":[
                            "region"
                        ]
                    }
                ]
            },
            {
                "id":"nice_to_have",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://company.example/company_rewards"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "rewards_number"
                        ]
                    }
                ]
            }
        ],
        "credential_sets":[
            {
                "options":[
                    [
                        "pid"
                    ],
                    [
                        "other_pid"
                    ],
                    [
                        "pid_reduced_cred_1",
                        "pid_reduced_cred_2"
                    ]
                ]
            },
            {
                "required":false,
                "options":[
                    [
                        "nice_to_have"
                    ]
                ]
            }
        ]
    },
    "D4":{
        "credentials":[
            {
                "id":"mdl-id",
                "format":"mso_mdoc",
                "meta":{
                    "doctype_value":"org.iso.18013.5.1.mDL"
                },
                "claims":[
                    {
                        "id":"given_name",
                        "path":[
                            "org.iso.18013.5.1",
                            "given_name"
                        ]
                    },
                    {
                        "id":"family_name",
                        "path":[
                            "org.iso.18013.5.1",
                            "family_name"
                        ]
                    },
                    {
                        "id":"portrait",
                        "path":[
                            "org.iso.18013.5.1",
                            "portrait"
                        ]
                    }
                ]
            },
            {
                "id":"mdl-address",
                "format":"mso_mdoc",
                "meta":{
                    "doctype_value":"org.iso.18013.5.1.mDL"
                },
                "claims":[
                    {
                        "id":"resident_address",
                        "path":[
                            "org.iso.18013.5.1",
                            "resident_address"
                        ]
                    },
                    {
                        "id":"resident_country",
                        "path":[
                            "org.iso.18013.5.1",
                            "resident_country"
                        ]
                    }
                ]
            },
            {
                "id":"photo_card-id",
                "format":"mso_mdoc",
                "meta":{
                    "doctype_value":"org.iso.23220.photoid.1"
                },
                "claims":[
                    {
                        "id":"given_name",
                        "path":[
                            "org.iso.18013.5.1",
                            "given_name"
                        ]
                    },
                    {
                        "id":"family_name",
                        "path":[
                            "org.iso.18013.5.1",
                            "family_name"
                        ]
                    },
                    {
                        "id":"portrait",
                        "path":[
                            "org.iso.18013.5.1",
                            "portrait"
                        ]
                    }
                ]
            },
            {
                "id":"photo_card-address",
                "format":"mso_mdoc",
                "meta":{
                    "doctype_value":"org.iso.23220.photoid.1"
                },
                "claims":[
                    {
                        "id":"resident_address",
                        "path":[
                            "org.iso.18013.5.1",
                            "resident_address"
                        ]
                    },
                    {
                        "id":"resident_country",
                        "path":[
                            "org.iso.18013.5.1",
                            "resident_country"
                        ]
                    }
                ]
            }
        ],
        "credential_sets":[
            {
                "options":[
                    [
                        "mdl-id"
                    ],
                    [
                        "photo_card-id"
                    ]
                ]
            },
            {
                "required":false,
                "options":[
                    [
                        "mdl-address"
                    ],
                    [
                        "photo_card-address"
                    ]
                ]
            }
        ]
    },
    "D5":{
        "credentials":[
            {
                "id":"pid",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://credentials.example.com/identity_credential"
                    ]
                },
                "claims":[
                    {
                        "id":"a",
                        "path":[
                            "last_name"
                        ]
                    },
                    {
                        "id":"b",
                        "path":[
                            "postal_code"
                        ]
                    },
                    {
                        "id":"c",
                        "path":[
                            "locality"
                        ]
                    },
                    {
                        "id":"d",
                        "path":[
                            "region"
                        ]
                    },
                    {
                        "id":"e",
                        "path":[
                            "date_of_birth"
                        ]
                    }
                ],
                "claim_sets":[
                    [
                        "a",
                        "c",
                        "d",
                        "e"
                    ],
                    [
                        "a",
                        "b",
                        "e"
                    ]
                ]
            }
        ]
    },
    "D6":{
        "credentials":[
            {
                "id":"my_credential",
                "format":"dc+sd-jwt",
                "meta":{
                    "vct_values":[
                        "https://credentials.example.com/identity_credential"
                    ]
                },
                "claims":[
                    {
                        "path":[
                            "last_name"
                        ],
                        "values":[
                            "Doe"
                        ]
                    },
                    {
                        "path":[
                            "first_name"
                        ]
                    },
                    {
                        "path":[
                            "address",
                            "street_address"
                        ]
                    },
                    {
                        "path":[
                            "postal_code"
                        ],
                        "values":[
                            "90210",
                            "90211"
                        ]
                    }
                ]
            }
        ]
    }
}
EOF
    cat << EOF | zexe example_dcql_query.zen example_dcql_query.data.json
Scenario 'dcql_query': validation
Given I have a 'dcql_query' named 'D1'
Given I have a 'dcql_query' named 'D2'
Given I have a 'dcql_query' named 'D3'
Given I have a 'dcql_query' named 'D4'
Given I have a 'dcql_query' named 'D5'
Given I have a 'dcql_query' named 'D6'
Then print the data
EOF
    save_output example_dcql_query.out.json
}

@test "DCQL: select credentials matching a DCQL query" {
    if date --version >/dev/null 2>&1; then
        # GNU date
        next_day=$(date -u -d "1 day" +"%Y-%m-%dT%H:%M:%SZ")
    else
        # BSD/macOS date
        next_day=$(date -u -v+1d +"%Y-%m-%dT%H:%M:%SZ")
    fi
    cat << EOF | save_asset dcql_query.data.json
{
    "my_query": {
        "credentials":  [
            {
                "id": "example_ldp_vc",
                "format": "ldp_vc",
                "meta": {
                    "type_values": [["IDCredential"]]
                },
                "claims": [
                    {"id": "a", "path": ["credentialSubject", "family_name"]},
                    {"id": "b", "path": ["credentialSubject", "given_name"]},
                    {"id": "c", "path": ["credentialSubject", "birthdate"]},
                    {"id": "d", "path": ["credentialSubject", "address", "country"], "values": ["DE", "IT"]}
                ],
                "claim_sets": [
                    ["a", "b", "d"],
                    ["a", "c", "d"]
                ]
            },
            {
                "id": "example_sd_jwt",
                "format": "dc+sd-jwt",
                "meta": {
                    "vct_values": ["discount_from_voucher"]
                },
                "claims": [
                    {"id": "a", "path": ["has_discount_from_voucher"], "values": [10, 20]},
                    {"id": "b", "path": ["iss"], "values": ["https://issuer1.zenswarm.forkbomb.eu/credential_issuer"]},
                    {"id": "c", "path": ["iat"]}
                ],
                "claim_sets": [
                    ["a", "b"],
                    ["b", "c"]
                ]
            }
        ]
    },
    "credentials_list": {
        "ldp_vc": [
            {
                "@context": [
                    "https://www.w3.org/2018/credentials/v1",
                    "https://www.w3.org/2018/credentials/examples/v1",
                    "https://w3id.org/security/data-integrity/v2"
                ],
                "id": "https://example.com/credentials/1872",
                "type": [
                    "VerifiableCredential",
                    "IDCredential"
                ],
                "issuer": "https://example.com/credential_issuer",
                "validUntil": "$next_day",
                "credentialSubject": {
                    "given_name": "Max",
                    "family_name": "Mustermann",
                    "birthdate": "1998-01-11",
                    "address": {
                        "street_address": "Sandanger 25",
                        "locality": "Musterstadt",
                        "postal_code": "123456",
                        "country": "DE"
                    }
                },
                "proof": {
                    "type": "DataIntegrityProof",
                    "cryptosuite": "eddsa-rdfc-2022",
                    "created": "2025-03-19T15:30:15Z",
                    "proofValue": "not a real signature proof",
                    "proofPurpose": "assertionMethod",
                    "verificationMethod": "did:example:issuer#keys-1"
                }
            },
            {
                "@context": [
                    "https://www.w3.org/2018/credentials/v1",
                    "https://www.w3.org/2018/credentials/examples/v1",
                    "https://w3id.org/security/data-integrity/v2"
                ],
                "id": "https://example.com/credentials/1872",
                "type": [
                    "VerifiableCredential",
                    "NOT MATCHING TYPE"
                ],
                "issuer": "https://example.com/credential_issuer",
                "validUntil": "$next_day",
                "credentialSubject": {
                    "given_name": "Max",
                    "family_name": "Mustermann",
                    "birthdate": "1998-01-11",
                    "address": {
                        "street_address": "Sandanger 25",
                        "locality": "Musterstadt",
                        "postal_code": "123456",
                        "country": "DE"
                    }
                },
                "proof": {
                    "type": "DataIntegrityProof",
                    "cryptosuite": "eddsa-rdfc-2022",
                    "created": "2025-03-19T15:30:15Z",
                    "proofValue": "not a real signature proof (not checked)",
                    "proofPurpose": "assertionMethod",
                    "verificationMethod": "did:example:issuer#keys-1"
                }
            },
            {
                "@context": [
                    "https://www.w3.org/2018/credentials/v1",
                    "https://www.w3.org/2018/credentials/examples/v1",
                    "https://w3id.org/security/data-integrity/v2"
                ],
                "id": "https://example.com/credentials/1872",
                "type": [
                    "VerifiableCredential",
                    "IDCredential"
                ],
                "issuer": "https://example.com/credential_issuer",
                "validUntil": "$next_day",
                "credentialSubject": {
                    "given_name": "Max",
                    "family_name": "Mustermann",
                    "birthdate": "1998-01-11",
                    "address": {
                        "street_address": "Sandanger 25",
                        "locality": "Musterstadt",
                        "postal_code": "123456",
                        "country": "NOT MATCHING COUNTRY"
                    }
                },
                "proof": {
                    "type": "DataIntegrityProof",
                    "cryptosuite": "eddsa-rdfc-2022",
                    "created": "2025-03-19T15:30:15Z",
                    "proofValue": "not a real signature proof (not checked)",
                    "proofPurpose": "assertionMethod",
                    "verificationMethod": "did:example:issuer#keys-1"
                }
            }
        ],
        "dc+sd-jwt": [
            "eyJhbGciOiAiRVMyNTYiLCAidHlwIjogImRjK3NkLWp3dCJ9.eyJfc2QiOiBbInlvTFZfYmt0dWZtMHBFaGFiSi1Rd1VxYUM5RmNMYkxIMDYwUkNQWjViTzAiXSwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJjbmYiOiB7Imp3ayI6IHsiY3J2IjogIlAtMjU2IiwgImt0eSI6ICJFQyIsICJ4IjogInpKLTR1d0VWVlYxQW9GcW1yZVlzUlh1SjhGbzVHRVVUeTZ0aklBdjdUcFkiLCAieSI6ICJWb1h2YTNUSkdzSjluOVlXNXcwamUwenpTaGZic3dBZ3pIcjVMRkJIM2xnIn19LCAiZXhwIjogMTc5MjE2NzU5OCwgImlhdCI6IDE3NjA2MzE1OTgsICJpc3MiOiAiaHR0cHM6Ly9pc3N1ZXIxLnplbnN3YXJtLmZvcmtib21iLmV1L2NyZWRlbnRpYWxfaXNzdWVyIiwgIm5iZiI6IDE3NjA2MzE1OTgsICJzdWIiOiAiZGlkOmR5bmU6c2FuZGJveC5zaWducm9vbTo0S0V5bVdnTERVZjFMTmNrZXhZOTZkZkt6NXZINzlkaURla2dMTVI5RldwSCIsICJ0eXBlIjogImRpc2NvdW50X2Zyb21fdm91Y2hlciJ9.oREhEn5mspszmYxJOYAyWV8WoAsC4A6ymf-TWEBhXAokFGYmgd0doIJZvbVdYKyRkuvte6dNJnbymhN5xUhdlQ~WyJFSmw3N2lEa1Mzc2tIQURPaTFSN1VBIiwgImhhc19kaXNjb3VudF9mcm9tX3ZvdWNoZXIiLCAxMF0~"
        ]
    }
}
EOF
    cat << EOF | zexe dcql_query.zen dcql_query.data.json
Scenario 'dcql_query': test
Given I have a 'dcql_query' named 'my_query'
Given I have a 'string dictionary' named 'credentials_list'
When create the credentials from 'credentials_list' matching the dcql_query 'my_query'
Then print the 'credentials'
EOF
    save_output dcql_query.out.json
    # done to avoid checking validUntil since it is time-dependent
    clean_output=$(echo "$output" | sed -E 's/"validUntil":"[^"]*Z"/"validUntil":"IGNORED"/g')
    expected='{"credentials":{"example_ldp_vc":[{"claim_path_sets":[["credentialSubject","family_name"],["credentialSubject","given_name"],["credentialSubject","address","country"]],"credential":{"@context":["https://www.w3.org/2018/credentials/v1","https://www.w3.org/2018/credentials/examples/v1","https://w3id.org/security/data-integrity/v2"],"credentialSubject":{"address":{"country":"DE","locality":"Musterstadt","postal_code":"123456","street_address":"Sandanger 25"},"birthdate":"1998-01-11","family_name":"Mustermann","given_name":"Max"},"id":"https://example.com/credentials/1872","issuer":"https://example.com/credential_issuer","proof":{"created":"2025-03-19T15:30:15Z","cryptosuite":"eddsa-rdfc-2022","proofPurpose":"assertionMethod","proofValue":"not a real signature proof","type":"DataIntegrityProof","verificationMethod":"did:example:issuer#keys-1"},"type":["VerifiableCredential","IDCredential"],"validUntil":"IGNORED"}},{"claim_path_sets":[["credentialSubject","family_name"],["credentialSubject","birthdate"],["credentialSubject","address","country"]],"credential":{"@context":["https://www.w3.org/2018/credentials/v1","https://www.w3.org/2018/credentials/examples/v1","https://w3id.org/security/data-integrity/v2"],"credentialSubject":{"address":{"country":"DE","locality":"Musterstadt","postal_code":"123456","street_address":"Sandanger 25"},"birthdate":"1998-01-11","family_name":"Mustermann","given_name":"Max"},"id":"https://example.com/credentials/1872","issuer":"https://example.com/credential_issuer","proof":{"created":"2025-03-19T15:30:15Z","cryptosuite":"eddsa-rdfc-2022","proofPurpose":"assertionMethod","proofValue":"not a real signature proof","type":"DataIntegrityProof","verificationMethod":"did:example:issuer#keys-1"},"type":["VerifiableCredential","IDCredential"],"validUntil":"IGNORED"}}],"example_sd_jwt":[{"claim_path_sets":[["has_discount_from_voucher"],["iss"]],"credential":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogImRjK3NkLWp3dCJ9.eyJfc2QiOiBbInlvTFZfYmt0dWZtMHBFaGFiSi1Rd1VxYUM5RmNMYkxIMDYwUkNQWjViTzAiXSwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJjbmYiOiB7Imp3ayI6IHsiY3J2IjogIlAtMjU2IiwgImt0eSI6ICJFQyIsICJ4IjogInpKLTR1d0VWVlYxQW9GcW1yZVlzUlh1SjhGbzVHRVVUeTZ0aklBdjdUcFkiLCAieSI6ICJWb1h2YTNUSkdzSjluOVlXNXcwamUwenpTaGZic3dBZ3pIcjVMRkJIM2xnIn19LCAiZXhwIjogMTc5MjE2NzU5OCwgImlhdCI6IDE3NjA2MzE1OTgsICJpc3MiOiAiaHR0cHM6Ly9pc3N1ZXIxLnplbnN3YXJtLmZvcmtib21iLmV1L2NyZWRlbnRpYWxfaXNzdWVyIiwgIm5iZiI6IDE3NjA2MzE1OTgsICJzdWIiOiAiZGlkOmR5bmU6c2FuZGJveC5zaWducm9vbTo0S0V5bVdnTERVZjFMTmNrZXhZOTZkZkt6NXZINzlkaURla2dMTVI5RldwSCIsICJ0eXBlIjogImRpc2NvdW50X2Zyb21fdm91Y2hlciJ9.oREhEn5mspszmYxJOYAyWV8WoAsC4A6ymf-TWEBhXAokFGYmgd0doIJZvbVdYKyRkuvte6dNJnbymhN5xUhdlQ~WyJFSmw3N2lEa1Mzc2tIQURPaTFSN1VBIiwgImhhc19kaXNjb3VudF9mcm9tX3ZvdWNoZXIiLCAxMF0~"},{"claim_path_sets":[["iss"],["iat"]],"credential":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogImRjK3NkLWp3dCJ9.eyJfc2QiOiBbInlvTFZfYmt0dWZtMHBFaGFiSi1Rd1VxYUM5RmNMYkxIMDYwUkNQWjViTzAiXSwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJjbmYiOiB7Imp3ayI6IHsiY3J2IjogIlAtMjU2IiwgImt0eSI6ICJFQyIsICJ4IjogInpKLTR1d0VWVlYxQW9GcW1yZVlzUlh1SjhGbzVHRVVUeTZ0aklBdjdUcFkiLCAieSI6ICJWb1h2YTNUSkdzSjluOVlXNXcwamUwenpTaGZic3dBZ3pIcjVMRkJIM2xnIn19LCAiZXhwIjogMTc5MjE2NzU5OCwgImlhdCI6IDE3NjA2MzE1OTgsICJpc3MiOiAiaHR0cHM6Ly9pc3N1ZXIxLnplbnN3YXJtLmZvcmtib21iLmV1L2NyZWRlbnRpYWxfaXNzdWVyIiwgIm5iZiI6IDE3NjA2MzE1OTgsICJzdWIiOiAiZGlkOmR5bmU6c2FuZGJveC5zaWducm9vbTo0S0V5bVdnTERVZjFMTmNrZXhZOTZkZkt6NXZINzlkaURla2dMTVI5RldwSCIsICJ0eXBlIjogImRpc2NvdW50X2Zyb21fdm91Y2hlciJ9.oREhEn5mspszmYxJOYAyWV8WoAsC4A6ymf-TWEBhXAokFGYmgd0doIJZvbVdYKyRkuvte6dNJnbymhN5xUhdlQ~"}]}}'
    assert_equal "$clean_output" "$expected"
}
