load ../bats_setup
load ../bats_zencode
SUBDOC=longfellow

@test "Generate longfellow circuit" {
    cat << EOF | zexe gen_longfellow_circuit.zen
Scenario longfellow
Given nothing
When I create the longfellow circuit with id '1'
Then print the 'longfellow circuit'
EOF
    save_output 'longfellow_circuit_1.json'
    assert_output ''
}
