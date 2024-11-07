load ../bats_setup
load ../bats_zencode
SUBDOC=logfmt

@test "Simple json log" {
	echo "logfmt=json,rngseed=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
Then print the 'random object'
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

	cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err
	cat $TMP/err | jq .

}

@test "Debug=3 json log" {
	echo "debug=3,logfmt=json,rngseed=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
Then print the 'random object'
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

	cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err
    cat $TMP/err | jq .

}

@test "Parser error json log" {
	echo "logfmt=json" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given nothing
When I create the array of '32' random objects of '256' bits
asdasdk asdaskd
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

    cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err \
		|| true
    cat $TMP/err | jq .

}


@test "Execution error json log" {
	echo "logfmt=json" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given I have a 'string' named 'not existing'
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

	cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err \
								  || true
    cat $TMP/err | jq .
}

@test "HEAP is a valid base64(json)" {
	echo "logfmt=json" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
and I verify the 'random object' is found in 'array'
Then print the 'random object'
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

	cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err \
								  || true
	# parse the HEAP line and remove the last double quote
	awk '/J64.*HEAP:/ {print(substr($3,1,length($3)-2))}' \
		$TMP/err > heap_dump
    cat heap_dump | base64 -d | jq .
}

@test "TRACE is a valid base64(json)" {
	echo "logfmt=json" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
and I verify the 'random object' is found in 'array'
Then print the 'random object'
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

	cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err \
								  || true
	# parse the HEAP line and remove the last double quote
	awk '/J64.*TRACE:/ {print(substr($3,1,length($3)-2))}' \
		$TMP/err > trace_dump
    cat trace_dump | base64 -d | jq .
}

@test "invalid transition error json logs" {
	echo "logfmt=json" > zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Rule unknown ignore
Given a ignored statement
Scenario 'ecdh': signature
Given nothing
Then print the string 'done'
EOF
    echo >> zencode_exec_stdin # keys
    echo >> zencode_exec_stdin # data
    echo >> zencode_exec_stdin # extra
    echo >> zencode_exec_stdin # context

	cat zencode_exec_stdin | ${ZENCODE_EXECUTABLE} > $TMP/out 2>$TMP/err \
                                  || true
	cat $TMP/err | jq .
}
