load ../bats_setup
load ../bats_zencode
SUBDOC=output

@test "Report success" {
	cat <<EOF | zexe random_array_success.zen
Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array' as 'number'
and print the 'aggregation' as 'number'
EOF
	save_output 'random_array.out'
	assert_output '{"aggregation":3271,"array":[89,80,83,31,98,10,79,97,11,39,82,39,38,59,94,95,91,92,61,18,4,67,77,67,36,10,0,22,42,3,49,12,17,66,45,49,77,60,21,66,50,20,67,37,4,95,86,51,53,12,96,22,20,17,82,98,54,39,24,91,81,19,20,57]}'
}

@test "Report failure" {
	cat <<EOF > no_string_failure.zen
Given I have a 'string' named 'string'
Then print the data
EOF
	run $ZENROOM_EXECUTABLE -z no_string_failure.zen
	assert_failure
}
