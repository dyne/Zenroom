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
    "pvss_s": "TubTlydO4PIGfFROYCFkRtt6mWeDP1o2/G3r8Uv4iBo=",
    "pvss_total" : "10",
    "pvss_quorum" : "6"
}
EOF
    cat <<EOF | zexe pvss_create_shares.zen pvss_pub_data.json
Scenario pvss
Given I have a 'base64' named 'pvss s'
Given I have a 'integer' named 'pvss total'
Given I have a 'integer' named 'pvss quorum'
Given I have a 'pvss public key array' named 'pvss participant pks'
When I create the pvss public shares of 'pvss s' with 'pvss total' quorum 'pvss quorum' using the public keys 'pvss participant pks'
Then print the 'pvss public shares'
and print the 'pvss quorum'
and print the 'pvss total'
EOF
    save_output pvss_issuer_proof.json
}

@test "pvss distribution verify shares" {
    cat <<EOF | zexe pvss_verify_enc_shares.zen pvss_issuer_proof.json
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'integer' named 'pvss total'
Given I have a 'pvss public shares'
When I verify the pvss public shares with 'pvss total' quorum 'pvss quorum'
Then print the string 'pvss public shares verification successful'
EOF
    save_output verify_proof_pvss.json
    assert_output '{"output":["pvss_public_shares_verification_successful"]}'
}

@test "pvss decryption of a share" {
    cat << EOF | save_asset pvss_decrypt_data.json
{
    "keyring" : {
        "pvss" : "K+QxIAYwFcdLNq8E3JoQ6f9QpQS2FX7Z6uiuuEaTzBg="
    },
    "pvss_public_key": "iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H"
}
EOF
    cat <<EOF | zexe pvss_decrypt_shares.zen pvss_decrypt_data.json pvss_issuer_proof.json
Scenario pvss
Given I have a 'keyring'
Given I have a 'pvss public key'
Given I have a 'pvss public shares'
When I create the secret share with public key 'pvss public key'
Then print the 'pvss secret share'
EOF
    save_output pvss_partecipant_proof.json
}

@test "pvss verify the secret shares" {
    cat << EOF | save_asset pvss_ver_decrypt_data.json
{
"pvss_secret_shares" : [
    {"dec_share":"gTJ3xhArivens+O+uOT9nj6QoeHW7qVl7f+Q9eCX/Ko9wvtm5YOhFmHW6LepXAlq","enc_share":"gXO4sk+M8/FttVbV3oxad0lKynMat9v93izZkjr/I9DrbS8S2WSxhz0eLs1qJpMd","index":"9","proof":["YknKionYWDaIUYRxQKBHImQoZa+/2SyIqtlXKtwP8po=","G2Jam5rHeMPStUoDRUFcj2qs79sW21jO4VZSE6erGP4="],"pub_key":"uYOkK6sAwyupym4FTG26Ddw/Rv8Yw0TJKdpu56va//9biltYaSUxmBlcgvsWLah/"},
    {"dec_share":"qXIBaWuWTEylR5yP1e8EYLwyhG0dNz80kZ7qXu/4s8m7s4T5eDZWLt0hLsyU+alB","enc_share":"tzqHq/qxs52DejnZhlgM9IIxTghbYsVdMDt/bNNbRB7tdcFHyfy6EKQFrBPQjtoD","index":"10","proof":["bVjHOmtNox3VgA6C3VB8UQD8TicFPCxyNeasB4CKpVY=","RqcYBaTfmz446V0Ns2J3phRMXWmZASOsBONMG8+tKkY="],"pub_key":"tIdHaimPwaX/YTx+w71MVSSOpze1ytmNodG/7duQCvSV/kuc/rm2gpJlUuBvazRa"},
    {"dec_share":"gjoMbXIE6XgyqhxHDnKn2T5DfpgEfSfgvNGgoAvio8+foUW4zM4Ngb+K1+fMeaqj","enc_share":"iRvERL/sxxi4xtKgw2nShMNJ47Q/gspR326ZdC3/xuHjx1meLng8XrLrA7eGrbWQ","index":"1","proof":["VhUX6OilGEI1MSng9312NQn+EXNGVZFswARNDvt/hC0=","Q1mIWMWs63jkk41Slc8tahOYfBRnMtjIOAHbX+cp5Lg="],"pub_key":"iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H"},
    {"dec_share":"rZGJ+iXuRT92oXhBJlatVtPmFb6pe7CSu0Iy47Z1kJnIA/LQUxiPsGuS+y2O+Hm3","enc_share":"tL57o4ouad+3S1ArBP1KbIWXxLNJ9nay0AhpRYywl7VrfrADeftBN/syMpZYG1AZ","index":"2","proof":["MfoFfP2Vdlk3jSDpU3AMEpGxdw4oInT38qREUjjezWw=","WTFphl5I8DbsTP+7v0dSHl1Z/iqWQRoWOQ60K+82f0s="],"pub_key":"tXZ7QIy8dZKRzNNzx1msrj4BMS1H5DXKPNQWdxHLWCUKdYbhEuEg26auYQ7LpDnh"},
    {"dec_share":"ht5U2Y+HxaDZH0d+DK2ao8r+HhSMKKfRS6ois7fVoOYpcnQIYb0gi7AFBJS1Se15","enc_share":"pGgI0dLU1ZwFJ0FUiqrebuX12FnVzPbgTd2XHB606mINxq0F0AM8vFkNmwb+QHMo","index":"3","proof":["BCHGhyutkqeUP/V6HAQ7fcZmYAOj1Em46WHVk7oRdzk=","LrdBBK9VbSBnBOY1AGH8TBDtnt5Dhcuf4yaDLrj4DJ4="],"pub_key":"h+HF0NNhVEbW6tcFi7+O6h/gAjehwQol0U+g+IF+Zc3kcuU5EAKkI9GHQc75oTvG"},
    {"dec_share":"mP3mLreKRVe/7bQHyxmNW7nNPYzk0E0YXwaeb9qEBUcVTZWkL9gG7JoyVXpZkUgi","enc_share":"uLq/otZep2uqB8uP1sczcQmfg2J9alVZQZrIBkKeYxKkGpaPLmF2tbxCrGNW40H7","index":"4","proof":["C8opO1p5eMDMNLVgMpnc/5og7uvGjbGP/PA0UQovPME=","VFat/LT/n78HQZbvXmal4psjuNWAsiIrrafE0bApv1Y="],"pub_key":"lQkUlMc6lDVWrNy0zihv2QlOgnJjYs+9htrNaPJjyw/MBeIunlSFx4i3rCmzNPFU"},
    {"dec_share":"qmN7TaCej/IBVj+0npR0Fz/OM966Kb+Da9uiHXwCCxxqCt4Bmybx46zKtm000d1h","enc_share":"ol26jmN/BAx2Fl3xt7mCbr2tKRocWn1Z2qEcDA0iZGj46OUf2WNXiwiH/lAB0djX","index":"5","proof":["U4iwNH4SAZ7B37roQOghVr5ga17Tzs/TxILErew2fzk=","QlagPeEGHgP+sESy0w0cKjLcHegQhteNyKXz6Mp6omk="],"pub_key":"luZHQDAd3MQitDIBqu/rrC27mP3sFwGrmuD1sIqs7mr40Z57wRwe5Q4/CCkhRgrT"},
    {"dec_share":"snH4Ic2dAnu1la0ltHKzAN925Tb+bkNIQNynTCuInyy9nu2Qyiaze8JZ2rFq77mw","enc_share":"gA2Sjhtnh0X63nCfxr09TpgnZMXAZu1yZvnFn3Yje6K5wop25gAreHSwUarSPOtX","index":"6","proof":["BYdXA1izaZDsT86YGpoaa1PWJoj8/sK/jQ3+1Znvrm8=","YWbDhNeawOaMdVYNUaPyBuyNhMH5S0UhFI9ldMiw1gI="],"pub_key":"jUc/GHUYbEaY6L8mCFnJYtUP8s2sqRwxph4d3q7Yj8auSY8G3dTFYSnTLZZdKhHy"},
    {"dec_share":"pzR4kf73TnFXv17XktP9ayKKmVWw9gEVzpk8WGnt+QtOLm7OJUcLBbMiT5ulH+sl","enc_share":"rnjuuo84qG0UUYacpMJ6oMoAukdWoCWu+0umRLFj//ko6OBVEGxnwPuZpByqBD0S","index":"7","proof":["WSk4JjbmqBmRlYub6LJisKno7FY6Yc2ljSYFfSLn06k=","TDmXrnuKGH45pFER4PshDU34XML06Pn9hcuKIwujpeY="],"pub_key":"mFAEK9EIvzKsMw3/HwF34aNpRtm3nzOxaS9+9qzGXUQT7WnwQnGhhfR0EMDCfU07"},
    {"dec_share":"sMxqKdrZpmP0VKjvDI2u4W4n/UJcVDwEnvZrtS866oAOh3rUtL2Ra3/T2LL2EIjD","enc_share":"hizreRLh6cdLGZF+3n3iy2zzrgeamPBBagcHiTSRGvN8SzMQ9FWA1B9WEwSSlqR+","index":"8","proof":["Ee2o8XVYl0GkADaD0/S/KZj9AbI00hrVNciSSEDFOX8=","NShq0xZjqprBwV4M3IvYhijYUoQ2j7mJBzCtlp1obaQ="],"pub_key":"hivaOVnaIRBhBgvE95RFA2UIMOlxpjDNuOpbnD4pZuxZgRrYsd1LrDigN6qxa437"}
]
}
EOF
    cat <<EOF | zexe pvss_ver_decrypt_shares.zen pvss_ver_decrypt_data.json
Scenario pvss
Given I have a 'pvss secret share array' named 'pvss secret shares'
When I create the pvss verified shares from 'pvss secret shares'
Then print the 'pvss verified shares'

EOF
    save_output pvss_verified_shares.json
}

@test "pvss reconstruct the secret 1" {
       cat << EOF | save_asset pvss_quorum.json
{
    "pvss_quorum" : "6"
}
EOF
    cat <<EOF | zexe pvss_reconstruct_secret1.zen pvss_verified_shares.json pvss_quorum.json
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'pvss verified shares'
When I compose the pvss secret using 'pvss verified shares' with quorum 'pvss quorum'
Then print the 'pvss secret'
EOF
    save_output pvss_secret1.json
    assert_output '{"pvss_secret":"rLSMxqqNGVZ2IEOIrN1xBDbOh5VNgNzM24qc+jI7hCV9ycP3xBSjeH1m8gOSkqVR"}'
}

@test "pvss reconstruct the secret 2" {
    cat << EOF | save_asset pvss_recon_sec_data.json
{
    "pvss_verified_shares":{"valid_indexes":["10","9","8","3","4","5"], "valid_shares" : [
        "qXIBaWuWTEylR5yP1e8EYLwyhG0dNz80kZ7qXu/4s8m7s4T5eDZWLt0hLsyU+alB",
        "gTJ3xhArivens+O+uOT9nj6QoeHW7qVl7f+Q9eCX/Ko9wvtm5YOhFmHW6LepXAlq",
        "sMxqKdrZpmP0VKjvDI2u4W4n/UJcVDwEnvZrtS866oAOh3rUtL2Ra3/T2LL2EIjD",
        "ht5U2Y+HxaDZH0d+DK2ao8r+HhSMKKfRS6ois7fVoOYpcnQIYb0gi7AFBJS1Se15",
        "mP3mLreKRVe/7bQHyxmNW7nNPYzk0E0YXwaeb9qEBUcVTZWkL9gG7JoyVXpZkUgi",
        "qmN7TaCej/IBVj+0npR0Fz/OM966Kb+Da9uiHXwCCxxqCt4Bmybx46zKtm000d1h"]
    },
    "pvss_quorum" : "6"
    
}
EOF
    cat <<EOF | zexe pvss_reconstruct_secret.zen pvss_recon_sec_data.json
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'pvss verified shares'
When I compose the pvss secret using 'pvss verified shares' with quorum 'pvss quorum'
Then print the 'pvss secret'
EOF
    save_output pvss_secret.json
    assert_output '{"pvss_secret":"rLSMxqqNGVZ2IEOIrN1xBDbOh5VNgNzM24qc+jI7hCV9ycP3xBSjeH1m8gOSkqVR"}'
}
