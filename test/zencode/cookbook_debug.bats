load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_debug

@test "debug-base script" {
    cat <<EOF | save_asset input.json
{
	"keyring": {
		   "eddsa": "CbAbexaForJ4ES27FR9SMCiNr33aG92CKH7qZG84tHa5",
		   "schnorr": "XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="
	}
}
EOF
    cat <<EOF | zexe main_script.zen input.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
Then print the data
EOF
}

@test "debug-backtrace" {
    cat <<EOF | zexe backtrace_script.zen input.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and backtrace

Then print the data
EOF
}

@test "debug-codec" {
    cat <<EOF | zexe codec_script.zen input.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and codec

Then print the data
EOF
}

@test "debug-config" {
    cat <<EOF | zexe config_script.zen input.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and config

Then print the data
EOF
}

@test "debug-debug" {
    cat <<EOF | zexe debug_script.zen input.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and debug

Then print the data
EOF
}

@test "debug-schema" {
    cat <<EOF | zexe schema_script.zen input.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and schema

Then print the data
EOF
}
