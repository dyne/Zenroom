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

@test "pvss decryption of a share" {
    cat << EOF | save_asset pvss_decrypt_data.json
{
    "keyring" : {
        "pvss" : "K+QxIAYwFcdLNq8E3JoQ6f9QpQS2FX7Z6uiuuEaTzBg="
    },
    "pvss_public_key": "iNt3+0VE0QWWahdEIQ14t4dpO4/Pw3J6g0LfSUQAbG14kDQN/Pe1dyc6/+0ja94H",
    "pvss_encrypted_shares": ["1","iRvERL/sxxi4xtKgw2nShMNJ47Q/gspR326ZdC3/xuHjx1meLng8XrLrA7eGrbWQ"]
}
EOF
    cat <<EOF | zexe pvss_decrypt_shares.zen pvss_decrypt_data.json
Scenario pvss
Given I have a 'keyring'
Given I have a 'pvss public key'
Given I have a 'pvss encrypted shares'
When I decrypt the share 'pvss encrypted shares'
Then print the 'pvss encrypted shares'
and print the 'pvss proof'
and print the 'pvss public key'
and print the 'pvss decrypted share'
EOF
    save_output pvss_partecipant_proof.json
}

@test "pvss verify the decrypted shares" {
    cat << EOF | save_asset pvss_ver_decrypt_data.json
{
    "pvss_proofs" : [
        ["48496978220889453395703088423350330052343417574728359080111674365022686156797",["20310874996608228900879552520399574567431925180586815682798426725914753921677"]],
        ["22605079225245264807805553613448219528872831958615849389697993037732386884972",["40343147336013476313523196293467002772913919602492821903684455382809761447755"]],
        ["1868927537440049112053458117291050294066409904723009508827611665904845289273",["21130172787501819626216082217939316625253905612569069778452412153641142062238"]],
        ["5332629013266312487490496042876934299386410780031325143046553859281977818305",["38147428943651242683322758374226494257608724767612577837960871983488315277142"]],
        ["37783473755771988459089136313911898117494479218805870635685174684362804199225",["30005702801736537986857502017406404715925881123046447071319576101237359813225"]],
        ["2500689138814712240826592815869563456060836780721996684809768921707161038447",["44055914135140623711131529575775713759561099811511293632463228305859956233730"]],
        ["40328671781621766334271923575745426611495379641206761265649106973718739407785",["34477533642759920023803481843370510890681490801248203343715413404464581944806"]],
        ["8109227183359395571638073764591923031903630146248442817344319682965439592831",["24043992133523631330909993529792508342649658993232631450586504565575779904932"]],
        ["44457036884640402834860288215022752960539620217988228197811911263796333638298",["12386223276359569539920188077517534595000676094369145829867802033893818439934"]],
        ["49458958059776805460062698179395050116803596161583584975153186336948676633942",["31957128654721895857143870682572853740383633775864708637647764773158695807558"]]],
    "pvss_decrypted_shares": [
        "gjoMbXIE6XgyqhxHDnKn2T5DfpgEfSfgvNGgoAvio8+foUW4zM4Ngb+K1+fMeaqj",
        "rZGJ+iXuRT92oXhBJlatVtPmFb6pe7CSu0Iy47Z1kJnIA/LQUxiPsGuS+y2O+Hm3",
        "ht5U2Y+HxaDZH0d+DK2ao8r+HhSMKKfRS6ois7fVoOYpcnQIYb0gi7AFBJS1Se15",
        "mP3mLreKRVe/7bQHyxmNW7nNPYzk0E0YXwaeb9qEBUcVTZWkL9gG7JoyVXpZkUgi",
        "qmN7TaCej/IBVj+0npR0Fz/OM966Kb+Da9uiHXwCCxxqCt4Bmybx46zKtm000d1h",
        "snH4Ic2dAnu1la0ltHKzAN925Tb+bkNIQNynTCuInyy9nu2Qyiaze8JZ2rFq77mw",
        "pzR4kf73TnFXv17XktP9ayKKmVWw9gEVzpk8WGnt+QtOLm7OJUcLBbMiT5ulH+sl",
        "sMxqKdrZpmP0VKjvDI2u4W4n/UJcVDwEnvZrtS866oAOh3rUtL2Ra3/T2LL2EIjD",
        "gTJ3xhArivens+O+uOT9nj6QoeHW7qVl7f+Q9eCX/Ko9wvtm5YOhFmHW6LepXAlq",
        "qXIBaWuWTEylR5yP1e8EYLwyhG0dNz80kZ7qXu/4s8m7s4T5eDZWLt0hLsyU+alB"
    ],
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
    "pvss_encrypted_shares":[
        ["1","iRvERL/sxxi4xtKgw2nShMNJ47Q/gspR326ZdC3/xuHjx1meLng8XrLrA7eGrbWQ"],
        ["2","tL57o4ouad+3S1ArBP1KbIWXxLNJ9nay0AhpRYywl7VrfrADeftBN/syMpZYG1AZ"],
        ["3","pGgI0dLU1ZwFJ0FUiqrebuX12FnVzPbgTd2XHB606mINxq0F0AM8vFkNmwb+QHMo"],
        ["4","uLq/otZep2uqB8uP1sczcQmfg2J9alVZQZrIBkKeYxKkGpaPLmF2tbxCrGNW40H7"],
        ["5","ol26jmN/BAx2Fl3xt7mCbr2tKRocWn1Z2qEcDA0iZGj46OUf2WNXiwiH/lAB0djX"],
        ["6","gA2Sjhtnh0X63nCfxr09TpgnZMXAZu1yZvnFn3Yje6K5wop25gAreHSwUarSPOtX"],
        ["7","rnjuuo84qG0UUYacpMJ6oMoAukdWoCWu+0umRLFj//ko6OBVEGxnwPuZpByqBD0S"],
        ["8","hizreRLh6cdLGZF+3n3iy2zzrgeamPBBagcHiTSRGvN8SzMQ9FWA1B9WEwSSlqR+"],
        ["9","gXO4sk+M8/FttVbV3oxad0lKynMat9v93izZkjr/I9DrbS8S2WSxhz0eLs1qJpMd"],
        ["10","tzqHq/qxs52DejnZhlgM9IIxTghbYsVdMDt/bNNbRB7tdcFHyfy6EKQFrBPQjtoD"]
    ] 
}
EOF
    cat <<EOF | zexe pvss_ver_decrypt_shares.zen pvss_ver_decrypt_data.json
Scenario pvss
Given I have a 'pvss public key array' named 'pvss participant pks'
Given I have a 'pvss encrypted shares array' named 'pvss encrypted shares'
Given I have a 'integer array' named 'pvss proofs'
Given I have a 'pvss public key array' named 'pvss decrypted shares'
When I verify the pvss decrypted shares
Then print the 'pvss valid shares'
and print the 'pvss valid indexes'

EOF
    save_output pvss_verified_shares.json
}

@test "pvss reconstruct the secret" {
    cat << EOF | save_asset pvss_ver_decrypt_data.json
{
    "pvss_indexes" : ["10","9","8","3","4","5"],
    "pvss_quorum" : "6",
    "pvss_decrypted_shares" : [
        "qXIBaWuWTEylR5yP1e8EYLwyhG0dNz80kZ7qXu/4s8m7s4T5eDZWLt0hLsyU+alB",
        "gTJ3xhArivens+O+uOT9nj6QoeHW7qVl7f+Q9eCX/Ko9wvtm5YOhFmHW6LepXAlq",
        "sMxqKdrZpmP0VKjvDI2u4W4n/UJcVDwEnvZrtS866oAOh3rUtL2Ra3/T2LL2EIjD",
        "ht5U2Y+HxaDZH0d+DK2ao8r+HhSMKKfRS6ois7fVoOYpcnQIYb0gi7AFBJS1Se15",
        "mP3mLreKRVe/7bQHyxmNW7nNPYzk0E0YXwaeb9qEBUcVTZWkL9gG7JoyVXpZkUgi",
        "qmN7TaCej/IBVj+0npR0Fz/OM966Kb+Da9uiHXwCCxxqCt4Bmybx46zKtm000d1h"
    ]
}
EOF
    cat <<EOF | zexe pvss_reconstruct_secret.zen pvss_ver_decrypt_data.json
Scenario pvss
Given I have a 'integer' named 'pvss quorum'
Given I have a 'integer array' named 'pvss indexes'
Given I have a 'pvss public key array' named 'pvss decrypted shares'
When I compose the pvss secret using 'pvss decrypted shares' indexed with 'pvss indexes'
Then print the 'pvss secret'
EOF
    save_output pvss_secret.json
    assert_output '{"pvss_secret":"rLSMxqqNGVZ2IEOIrN1xBDbOh5VNgNzM24qc+jI7hCV9ycP3xBSjeH1m8gOSkqVR"}'
}
