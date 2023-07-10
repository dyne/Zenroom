load ../bats_setup
load ../bats_zencode
SUBDOC=pvss

@test "pvss initialization" {
    cat <<EOF | zexe create_pvss_sk.zen
Scenario pvss
Given I am known as 'Alice'
When I create the keyring
and I create the pvss key
Then print my 'keyring'
EOF
    save_output create_pvss_sk.json
    cat <<EOF | zexe create_pvss_pk.zen create_pvss_sk.json
Scenario pvss
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the pvss public key
Then print my 'pvss public key'
EOF
    save_output create_pvss_pk.json
}

@test "pvss distribution create shares" {
    cat << EOF | save_asset pvss_pub_data.json
{
    "pvss_participant_pks": [
        "iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H",
        "tXZ7QIy8dZKRzNNzx1msrj4BMS1H5DXKPNQWdxHLWCUKdYbhEuEg26auYQ7LpDnh",
        "h+HF0NNhVEbW6tcFi7+O6h/gAjehwQol0U+g+IF+Zc3kcuU5EAKkI9GHQc75oTvG",
        "lQkUlMc6lDVWrNy0zihv2QlOgnJjYs+9htrNaPJjyw/MBeIunlSFx4i3rCmzNPFU",
        "luZHQDAd3MQitDIBqu/rrC27mP3sFwGrmuD1sIqs7mr40Z57wRwe5Q4/CCkhRgrT",
        "jUc/GHUYbEaY6L8mCFnJYtUP8s2sqRwxph4d3q7Yj8auSY8G3dTFYSnTLZZdKhHy",
        "mFAEK9EIvzKsMw3/HwF34aNpRtm3nzOxaS9+9qzGXUQT7WnwQnGhhfR0EMDCfU07",
        "hivaOVnaIRBhBgvE95RFA2UIMOlxpjDNuOpbnD4pZuxZgRrYsd1LrDigN6qxa437",
        "uYOkK6sAwyupym4FTG26Ddw/Rv8Yw0TJKdpu56va//9biltYaSUxmBlcgvsWLah/",
        "tIdHaimPwaX/YTx+w71MVSSOpze1ytmNodG/7duQCvSV/kuc/rm2gpJlUuBvazRa"
    ],
    "pvss_s": "35688237357964554424910256379692958620043154328334738115441976865761925826586"
}
EOF
    cat <<EOF | zexe pvss_create_shares.zen pvss_pub_data.json
Scenario pvss
Given I have a 'integer' named 'pvss s'
Given I have a 'pvss public key array' named 'pvss participant pks'
When I create the pvss secret shares of 'pvss s' with '10' quorum '6' using the public keys 'pvss participant pks'
Then print the 'pvss cs'
and print the 'pvss encrypted shares'
and print the 'pvss proof'
and print the 'pvss quorum'
and print the 'pvss total'
and print the 'pvss participant pks'
EOF
    save_output pvss_issuer_proof.json
}

@test "pvss distribution verify shares" {
    cat <<EOF | zexe pvss_verify_enc_shares.zen pvss_issuer_proof.json
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'integer' named 'pvss total'
Given I have a 'base64 array' named 'pvss participant pks'
Given I have a 'integer array' named 'pvss proof'
Given I have a 'base64 array' named 'pvss cs'
Given I have a 'pvss encrypted shares'
When I verify the pvss encrypted shares
Then print the string 'pvss encrypted shares verification successful'
EOF
    save_output verify_proof_bbs.json
    assert_output '{"output":["pvss_encrypted_shares_verification_successful"]}'
}
