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
	assert_output '{"aggregation":"6310","array":["86","136","100","71","140","67","119","56","107","87","49","60","141","78","135","95","121","118","59","128","147","132","126","147","76","61","133","55","115","96","124","108","61","87","66","94","128","93","104","142","58","63","68","69","102","135","123","66","88","69","101","99","50","86","102","77","127","102","136","98","81","135","103","124"]}'
}

@test "Report failure" {
	cat <<EOF > no_string_failure.zen
Given I have a 'string' named 'string'
Then print the data
EOF
	run $ZENROOM_EXECUTABLE -z no_string_failure.zen
	assert_line --partial "Cannot find 'string' anywhere (null value?)"
}
