load ../bats_setup
load ../bats_zencode
SUBDOC=credential

@test "Credential partecipant keygen" {
    cat << EOF | zexe credentialParticipantKeygen.zen
Scenario credential: credential keygen
Given that I am known as 'Alice'
When I create the credential key
Then print my 'keyring'
EOF
    save_output 'credentialParticipantKeyring.json'
    assert_output '{"Alice":{"keyring":{"credential":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k="}}}'
}

@test "Credential partecipant signature request" {
    cat << EOF | zexe credentialParticipantSignatureRequest.zen credentialParticipantKeyring.json
Scenario credential: create request
Given that I am known as 'Alice'
and I have my valid 'keyring'
When I create the credential request
Then print my 'credential request'
EOF
    save_output 'credentialParticipantSignatureRequest.json'
    assert_output '{"Alice":{"credential_request":{"commit":"AhL6ktfHJ1U3m80PNAvj+9qqimlBQSP7Jm8kqRl/cQSdQj729BljAAqjwGx9RSVsmg==","pi_s":{"commit":"GudcgN/bvlqYF/+XhtR8h3mHytJ2GAQWTe7OeQ7KZw0=","rk":"NNRuCDqBDa/6mifTh7uRe6iGJYHRBtrpenV1oogoPKE=","rm":"Wly+eTmSM40uM7HkUmKB4PZmRFX7Ajua6ZZdylW4eKg=","rr":"HfDYOAJCh49v4NQsVzXbTuzju1vPiet1AGkb8U2Q79c="},"public":"AhI6Hg/QJKYeF1E3O50Wwr1mYHs8rCHX+7HfDRM9zrr/Y2bw6rQiip+EGP1PrOOMXw==","sign":{"a":"Ahn2OgUGQd/EAU7DgTY9mq0HaDfxFFajWSA463x8E8H5Xoks2TdaP+WlokFQSeH4BA==","b":"AhhFCFOlnjkjlZdFzTKtiIoc9ibm0MezXYTpqnMzjwv7fRJP60qgLinjxnDYRg0w4g=="}}}}'
}

# credential issuance
@test "Credential issuer keygen" {
    cat << EOF | zexe credentialIssuerKeygen.zen
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer key
Then print my 'keyring'
EOF
    save_output 'credentialIssuerKeyring.json'
    assert_output '{"MadHatter":{"keyring":{"issuer":{"x":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k=","y":"abYTJShT0ZBKU+ZwJlEIPNinT6TFU+unaKMEZ+u3kbs="}}}}'
}

@test "Credential issuer public key" {
    cat << EOF | zexe credentialIssuerPublishpublic_key.zen credentialIssuerKeyring.json
Scenario credential: publish public_key
Given that I am known as 'MadHatter'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
    save_output 'credentialIssuerpublic_key.json'
    assert_output '{"MadHatter":{"issuer_public_key":{"alpha":"DCVR1myU23U3freVJYRhzFy20WPOhzqn/JyEZMNN/y+gj7KvdEDKfuVjBMy6z7O4AbU9noh14cse4Dxs06XyQW7skeIDzX8r1P1Ldf4D6w6/xI2tbpdC65LeZYkKpTe0ABWqN14boyg0tZhdFaXti3+MKbZx4A6isA+c9tGoDLhVbFtvvXAY3gyzD4paCwG/AL5yjOcrIqiTiOaHJbEtwkQ/OfC3j/xfuPR1yTTq7sgTlk0HbiTemeopEn10F5pO","beta":"FwWLOfRBAoZKfykEvq26iNn2D64gvwgCfinWWZnG4HotCuomB6EB9qJ0sinpV5LNB6GdkrKU3wvYMUU+fBMX8mtR77E3x/ljbqpwwpcmjB9YtONG1peywJvRhXqhIBJSALFTXAB2Y1XtM63Uw5/CBex8zH3wXyYU6sv/ctKi5bUZ2Zzqua9Q8LMqtgLsrrB9GDKbmPT1einkXVMLX0kuJV/AOTnA57q91HKXMCvlvlKs/sr5mJ70FchdEZl0UHIV"}}}'
}

@test "Credential issuer sign request" {
    cat << EOF | zexe credentialIssuerSignRequest.zen credentialParticipantSignatureRequest.json credentialIssuerKeyring.json
Scenario credential: issuer sign
Given that I am known as 'MadHatter'
and I have my valid 'keyring'
and I have a 'credential request' inside 'Alice'
When I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
    save_output 'credentialIssuerSignedCredential.json'
    assert_output '{"credential_signature":{"a_tilde":"AwfpaOQwAjjfD7Z7/rXrv3F+qqw3R1JvhQJFrBvLCN52k8FcwtVIXWUaQ+D9cGiaaA==","b_tilde":"AggzyoZNliGTjzGvYoT/1z0YvIACmnLv5/+PSjEmvM0SZQFtYv2elSVKC4p+lEPTOQ==","h":"AhL6ktfHJ1U3m80PNAvj+9qqimlBQSP7Jm8kqRl/cQSdQj729BljAAqjwGx9RSVsmg=="},"issuer_public_key":{"alpha":"DCVR1myU23U3freVJYRhzFy20WPOhzqn/JyEZMNN/y+gj7KvdEDKfuVjBMy6z7O4AbU9noh14cse4Dxs06XyQW7skeIDzX8r1P1Ldf4D6w6/xI2tbpdC65LeZYkKpTe0ABWqN14boyg0tZhdFaXti3+MKbZx4A6isA+c9tGoDLhVbFtvvXAY3gyzD4paCwG/AL5yjOcrIqiTiOaHJbEtwkQ/OfC3j/xfuPR1yTTq7sgTlk0HbiTemeopEn10F5pO","beta":"FwWLOfRBAoZKfykEvq26iNn2D64gvwgCfinWWZnG4HotCuomB6EB9qJ0sinpV5LNB6GdkrKU3wvYMUU+fBMX8mtR77E3x/ljbqpwwpcmjB9YtONG1peywJvRhXqhIBJSALFTXAB2Y1XtM63Uw5/CBex8zH3wXyYU6sv/ctKi5bUZ2Zzqua9Q8LMqtgLsrrB9GDKbmPT1einkXVMLX0kuJV/AOTnA57q91HKXMCvlvlKs/sr5mJ70FchdEZl0UHIV"}}'

}

@test "Credential participant aggregate credential" {
    cat << EOF | zexe credentialParticipantAggregateCredential.zen credentialIssuerSignedCredential.json credentialParticipantKeyring.json
Scenario credential: aggregate signature
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'credential signature'
When I create the credentials
Then print my 'credentials'
and print my 'keyring'
EOF
    save_output 'credentialParticipantAggregatedCredential.json'
    assert_output '{"Alice":{"credentials":{"h":"AhL6ktfHJ1U3m80PNAvj+9qqimlBQSP7Jm8kqRl/cQSdQj729BljAAqjwGx9RSVsmg==","s":"AhQPFzhhDn7kJioh1DTXPs4zfm2iIAkX3zhqj92tjZeIRIWdZaaet+hBmpqMMRnKNg=="},"keyring":{"credential":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k="}}}'
}

# zero-knowledge credential proof emission and verification
@test "Credential participant create proof" {
    cat << EOF | zexe credentialParticipantCreateProof.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
Scenario credential: create proof
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'issuer public key' inside 'MadHatter'
and I have my 'credentials'
When I aggregate all the issuer public keys
and I create the credential proof
Then print the 'credential proof'
EOF

    save_output 'credentialParticipantProof.json'
    assert_output '{"credential_proof":{"kappa":"GNZ+cD1N6IMaqUCtC7028XITDJ3UWdHgGlkDsgqybKRvYxEokDzLNxF10KvPEr3qFvnH37QcaGP76R++yLjlFmKoxX8fol6HwXZWM7EEXd1tHm5ALtOb8LSR+KNNZVo+FACA/9R14D7QaiO8pBSxO5Xtb30J1c+Zamsr5eQuY8m6NvzA1teVH5wjwBDvnubtCmCKN86mcQWp7Y3gZCyprp11fp7MMV2YYf0i39hS8kOa9kDzIypmqXFitqXtC80q","nu":"AwaXYNSgY36mGkPXO832lfzqKKmc309ZuhQBWQPB2ABqi0EOwEk/ENBZ5/biLXpuHA==","pi_v":{"c":"FwleJBD8AqhHHVNSXOrhuyXgkmksJWljF2Tvpm6bv/A=","rm":"UTmcAbKE4Uzj8vbncJpk9O6fuJUmaiHRElOLHIMOy0g=","rr":"PZ6Kdd3vSF2jn1qMALSinm4v0Zk1NFgfn/qWfJXLD9o="},"sigma_prime":{"h_prime":"AhClGrLHKllUz2+RcrIKAWAmfsCzz2OwERAl6ssXOZV1shH781APwR27jyd8MqmBXA==","s_prime":"AgR2e2s17otCJ3MF1X2OO3RMzVoShKseY9nL192nGzWf1YbQp6Lmtjl2hMM4ZrJBWQ=="}}}'
}

@test "Credential anyone verify proof" {
    cat << EOF | zexe credentialAnyoneVerifyProof.zen credentialParticipantProof.json credentialIssuerpublic_key.json
Scenario credential: verify proof
Given that I have a 'issuer public key' inside 'MadHatter'
and I have a 'credential proof'
When I aggregate all the issuer public keys
When I verify the credential proof
Then print the string 'the proof matches the public_key! So you can add zencode after the verify statement, that will execute only if the match occurs.'
EOF
    save_output 'credentialAnyoneVerifyProof.json'
    assert_output '{"output":["the_proof_matches_the_public_key!_So_you_can_add_zencode_after_the_verify_statement,_that_will_execute_only_if_the_match_occurs."]}'

}

@test "Centralized credential issuance" {
    cat << EOF | zexe centralizedCredentialIssuance.zen credentialIssuerKeyring.json
Scenario credential: Centralized credential issuance
Given that I am known as 'MadHatter'
and I have my 'keyring'
When I create the credential key
and I create the credential request
and I create the credential signature
and I create the credentials
When I remove the 'issuer' from 'keyring'
Then print the 'credentials'
and print the 'keyring'
EOF
    save_output 'centralizedCredentialIssuance.json'
}
