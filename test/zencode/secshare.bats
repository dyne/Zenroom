load ../bats_setup
load ../bats_zencode
SUBDOC=secshare


@test "Participant creates shared secret" {
    cat <<EOF  | save_asset Secret.json
{
	"32BytesSecret":"myMilkshakeBringsAllTheBoysTo..."
}
EOF



    cat <<EOF | zexe createSharedSecret.zen Secret.json
# Let's define the scenario, we'll need the 'secshare' here
Scenario secshare: create a shared secret

# We'll start from a secret, which can be max 32 bytes in length
Given I have a 'string' named '32BytesSecret'

# Here we are creating the "secret shares", the output will be an array of pairs of numbers
# The quorum represents the minumum amount of secret shares needed to
# rebuild the secret, and it can be configured
When I create the secret shares of '32BytesSecret' with '9' quorum '5'

# Here we rename the output and print it out
and I rename the 'secret shares' to 'mySharedSecret'
Then print the 'mySharedSecret'
EOF

    save_output 'sharedSecret.json'
    assert_output '{"mySharedSecret":[{"x":"R/KKaTDVboaz/Of+Z9rEPaI2XwNSbMGqyqi4omZ74zg=","y":"WPk3EoZP+goC2PYv8eXNqHbXNwiaRmTjWTD2EyNQI8s="},{"x":"+cVAswi5yt+o7Dp9D57bSkM99aQiLPjzCMWvMENOf7o=","y":"UpOETaeBIC2d6g9Otx902usUCqCxlVN9rLzKFKIWTZ8="},{"x":"bODkB2YcY9egXPXU3AzbEbb90Mr1+ir6EEbN3PeXaJw=","y":"ZmycrsVl4z8xOOflILZ0vX8h0aDjRi+4WDwGPQNW1H0="},{"x":"imCvoxefw04xZ2ZSGaZmNCgUEIy5hphyYB9p7Cht9Ko=","y":"aY9QrYTZVGIP3lGCnWXsLfzqxVEUEE2Qq4zA26R2cdg="},{"x":"Fufxl9MdlotSfCiQ24zdPSl/FfPE1652+WfJOGGm8oA=","y":"xLQeXS74qYYllfALMuzq0WeBexJFRrsFIsfJ6jPKLG0="},{"x":"Tblj4YSvs+cBW+DUVJXO4Yjv3TS5ENQmlqQUsfXIsak=","y":"UIbBDT84YaFX7BAAgU5rlc0YUCndAHMt4y7A4Ftv6Ag="},{"x":"9m8rP9iXb/gsGDfwfDJcaNc8bF5uwzvxkHhD5zjAZzQ=","y":"WuAE6LvIizFFlzZDoB0J+ZGKSfF4YDcK7L4IyMgYv5g="},{"x":"pZGQLePO8pDYUSOhn4mCq8/wDiHm9NdxHgeaiQu1Tr8=","y":"uVWPG7walRnYPbQBx0l86hZ05EXnaaK66SDmJXhfdJ0="},{"x":"YoTYTbQlzvxjOjV2wJiKgU9+7hAuLMjqZIt3cfRXG1w=","y":"fD+peHDN9FcDFbsGLBroEa3y/jsKl8Je9k64/ZO1oVg="}]}'
}

@test "pick 5 random parts" {
    cat <<EOF | zexe removeShares.zen Secret.json sharedSecret.json

# Here we load the "secret shares", which is a an array of base64 numbers
Given I have a 'base64 array' named 'mySharedSecret'

# Here we are simply removing 4 randomly chosen shares from the array,
# so that only 4 are left.

When I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'
and I delete 'random object'
and I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'
and I delete 'random object'
and I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'
and I delete 'random object'
and I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'

# Now we have an array with 5 shares that print out
When I rename the 'mySharedSecret' to 'my5partsOfTheSharedSecret'
Then print the 'my5partsOfTheSharedSecret'
EOF
    save_output 'sharedSecret5parts.json'
    assert_output '{"my5partsOfTheSharedSecret":[{"x":"+cVAswi5yt+o7Dp9D57bSkM99aQiLPjzCMWvMENOf7o=","y":"UpOETaeBIC2d6g9Otx902usUCqCxlVN9rLzKFKIWTZ8="},{"x":"bODkB2YcY9egXPXU3AzbEbb90Mr1+ir6EEbN3PeXaJw=","y":"ZmycrsVl4z8xOOflILZ0vX8h0aDjRi+4WDwGPQNW1H0="},{"x":"Fufxl9MdlotSfCiQ24zdPSl/FfPE1652+WfJOGGm8oA=","y":"xLQeXS74qYYllfALMuzq0WeBexJFRrsFIsfJ6jPKLG0="},{"x":"9m8rP9iXb/gsGDfwfDJcaNc8bF5uwzvxkHhD5zjAZzQ=","y":"WuAE6LvIizFFlzZDoB0J+ZGKSfF4YDcK7L4IyMgYv5g="},{"x":"pZGQLePO8pDYUSOhn4mCq8/wDiHm9NdxHgeaiQu1Tr8=","y":"uVWPG7walRnYPbQBx0l86hZ05EXnaaK66SDmJXhfdJ0="}]}'

}


@test "Recompose the secret shares" {
    cat <<EOF | zexe composeSecretShares.zen sharedSecret5parts.json
Scenario secshare: recompose the secret shares

# Here we are loading the "secret shares"
Given I have a 'secret shares' named 'my5partsOfTheSharedSecret'

# Here we are testing if the secret shares can be recomposed to form the password
# in case the quorum isn't reached or isn't correct, Zenroom will anyway output a string,
# that will be different from the original secret.
# if the quorum is correct, the original secret should be printed out.
when I compose the secret using 'my5partsOfTheSharedSecret'
when I rename 'secret' to 'composed secret'
Then print the 'composed secret' as 'string'
EOF
    save_output 'composedSecretShares.json'
    assert_output '{"composed_secret":"myMilkshakeBringsAllTheBoysTo..."}'
}

@test "check the quorum" {
    cat <<EOF | zexe checkSecret.zen Secret.json composedSecretShares.json
Scenario secshare
Given I have a 'string' named '32BytesSecret'
Given I have a 'string' named 'composed secret'
When I verify '32BytesSecret' is equal to 'composed secret'
Then print string 'Secrets match'
EOF
    save_output 'checkSecret.out'
    assert_output '{"output":["Secrets_match"]}'
}


@test "split long secret in two and compose" {
    cat <<EOF | save_asset 64secret.json
{ "secret": "3958dcd0a9161543d2b56016b5c79ad6cd5859f583c30c2ad4fc64381829146814e169a890cdc09d15669d663cc7e54103ee85ba120991e4f28038b9630dbcca" }
EOF

    cat <<EOF | zexe 64secret.zen 64secret.json
Rule check version 2.0.0
Scenario secshare: create a shared secret

Given I have a 'hex' named 'secret'

When I split the rightmost '32' bytes of 'secret'
and I create the secret shares of 'rightmost' with '5' quorum '3'
and I rename 'secret shares' to 'rightmost shares'

When I split the leftmost '32' bytes of 'secret'
and I create the secret shares of 'leftmost' with '5' quorum '3'
and I rename 'secret shares' to 'leftmost shares'

Then print the 'rightmost shares'
and print the 'leftmost shares'
EOF
    save_output '64shares.json'
    assert_output '{"leftmost_shares":[{"x":"Tblj4YSvs+cBW+DUVJXO4Yjv3TS5ENQmlqQUsfXIsak=","y":"M5hzrldADqEJrEOoOTGZ2QN5pqAnn7j7y0VTx4IsmMo="},{"x":"9m8rP9iXb/gsGDfwfDJcaNc8bF5uwzvxkHhD5zjAZzQ=","y":"s6520MAkiD+ds3mnL1xaO8I+8O0NJAg173aFbuUrltk="},{"x":"pZGQLePO8pDYUSOhn4mCq8/wDiHm9NdxHgeaiQu1Tr8=","y":"0s9HRgbGZA51s8NRU4wg5JiPaWdTvZ8EMQpcmLRrECo="},{"x":"YoTYTbQlzvxjOjV2wJiKgU9+7hAuLMjqZIt3cfRXG1w=","y":"I1PZkMJk+uBI4RKulx14h72J9WRpXgfd6GA/udG8sZU="},{"x":"AqfAdIJUgUEsNkXcLYVgkp7k5f09DcbY4MwLxDMcGdI=","y":"Xipo6t0v+Kd+8u2rjkTrNI1UZmbqGAbvJrKQBjcNSe4="}],"rightmost_shares":[{"x":"ZJytDokSyFcVIYJnO+hLiaw6ha4PoB255y1wEj39FNo=","y":"lj7qAXuo+gyAF0ZoWpPttTOC/3o23reHwawJrADnKXk="},{"x":"wlvccXxefRmb4s2k9hThxGba0VKO3H/C8i1GuOz3C8c=","y":"dOQbftDb1C5/H4DlXHjFMAnJFbz/i4LDUCa4sI47XOA="},{"x":"R/KKaTDVboaz/Of+Z9rEPaI2XwNSbMGqyqi4omZ74zg=","y":"WX8gfTqBxiAJXm+PLMnP5dIQQME+a0sVESZCsMUewDM="},{"x":"+cVAswi5yt+o7Dp9D57bSkM99aQiLPjzCMWvMENOf7o=","y":"C53CBK9eeYf4CziLTVCvUco+0ehXwpeYdzfMrH0+h/4="},{"x":"bODkB2YcY9egXPXU3AzbEbb90Mr1+ir6EEbN3PeXaJw=","y":"AZOk/gEPdTxkMpXu01Vx7Gn9YQ4lRW+6HG1UuF+lzJM="}]}'
}

@test "recompose long secret" {
    cat <<EOF | zexe 64compose.zen 64shares.json 64secret.json
Rule check version 2.0.0
Scenario secshare: compose a shared secret

Given I have a 'secret shares' named 'rightmost shares'
and I have a 'secret shares' named 'leftmost shares'
and I have a 'hex' named 'secret'


When I rename 'secret' to 'original secret'

When I compose the secret using 'rightmost shares'
and I rename 'secret' to 'rightmost secret'

and I compose the secret using 'leftmost shares'
and I rename 'secret' to 'leftmost secret'

and I append 'rightmost secret' to 'leftmost secret'
and I rename 'leftmost secret' to 'composed secret'

and I verify 'original secret' is equal to 'composed secret'

Then print string 'SECRETS MATCH'
EOF
    save_output '64compose.out'
    assert_output '{"output":["SECRETS_MATCH"]}'
}


@test "create a shared secret" {
    cat <<EOF | save_asset 32secret.json
{ "secret": "f40e744984d511506a3ea1e52417c0a49caa11762626c7cae8f5302138205a07" }
EOF
    cat <<EOF | zexe 32secret.zen 32secret.json
Rule check version 2.0.0
Scenario secshare: create a shared secret

Given I have a 'hex' named 'secret'

When I create the secret shares of 'secret' with '5' quorum '3'

Then print the 'secret shares'
EOF
    save_output '32shares.json'
    assert_output '{"secret_shares":[{"x":"ZJytDokSyFcVIYJnO+hLiaw6ha4PoB255y1wEj39FNo=","y":"dWv0om+wSr/U70rnQePJGMw+izZK++1tuCEBE9X5x3M="},{"x":"wlvccXxefRmb4s2k9hThxGba0VKO3H/C8i1GuOz3C8c=","y":"VBEmH8TjJOHT94VkQ8igk6KEoXkTqLipRpuwGGNN+to="},{"x":"R/KKaTDVboaz/Of+Z9rEPaI2XwNSbMGqyqi4omZ74zg=","y":"OKwrHi6JFtNeNnQOFBmrSWrLzH1SiID7B5s6GJoxXi0="},{"x":"+cVAswi5yt+o7Dp9D57bSkM99aQiLPjzCMWvMENOf7o=","y":"6srMpaNlyjtM4z0KNKCKtWL6XaRr381+bazEFFJRJTs="},{"x":"bODkB2YcY9egXPXU3AzbEbb90Mr1+ir6EEbN3PeXaJw=","y":"4MCvnvUWxe+5CpptuqVNUAK47Mo5YqWgEuJMIDS4adA="}]}'
}



@test "recreate the secret" {
    cat <<EOF | zexe 32compose.zen 32shares.json 32secret.json
Rule check version 2.0.0
Scenario secshare: compose a shared secret

Given I have a 'secret shares'
and I have a 'hex' named 'secret'

When I rename 'secret' to 'original secret'
and I compose the secret using 'secret shares'
and I verify 'original secret' is equal to 'secret'

Then print string 'SECRETS MATCH'
EOF

    save_output '32compose.out'
    assert_output '{"output":["SECRETS_MATCH"]}'
}

# TODO: add test that fails for order bigger then the prime chosen
# for secret sharing
