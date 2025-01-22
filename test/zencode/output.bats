load ../bats_setup
load ../bats_zencode
SUBDOC=output

@test "Report success" {
	cat <<EOF | zexe random_array_success.zen
Given nothing
When I create the random array with '64' numbers modulo '100'
and I create the aggregation of array 'random array'
Then print the 'random array'
and print the 'aggregation'
EOF
	save_output 'random_array.out'
	assert_output '{"aggregation":3335,"random_array":[90,81,84,32,99,11,80,98,12,40,83,40,39,60,95,96,92,93,62,19,5,68,78,68,37,11,1,23,43,4,50,13,18,67,46,50,78,61,22,67,51,21,68,38,5,96,87,52,54,13,97,23,21,18,83,99,55,40,25,92,82,20,21,58]}'
}

@test "Report failure" {
	cat <<EOF > no_string_failure.zen
Given I have a 'string' named 'string'
Then print the data
EOF
	run $ZENROOM_EXECUTABLE -z no_string_failure.zen
	assert_line --partial "Cannot find 'string' anywhere (null value?)"
}
