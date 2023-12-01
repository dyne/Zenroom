load ../bats_setup
load ../bats_zencode
SUBDOC=output

@test "Report success" {
	cat <<EOF | zexe random_array_success.zen
Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array'
and print the 'aggregation'
EOF
	save_output 'random_array.out'
	assert_output '{"aggregation":"3174","array":["37","87","51","22","91","18","70","7","58","38","0","11","92","29","86","46","72","69","10","79","98","83","77","98","27","12","84","6","66","47","75","59","12","38","17","45","79","44","55","93","9","14","19","20","53","86","74","17","39","20","52","50","1","37","53","28","78","53","87","49","32","86","54","75"]}'
}

@test "Report failure" {
	cat <<EOF > no_string_failure.zen
Given I have a 'string' named 'string'
Then print the data
EOF
	run $ZENROOM_EXECUTABLE -z no_string_failure.zen
	assert_line --partial "Cannot find 'string' anywhere (null value?)"
}
