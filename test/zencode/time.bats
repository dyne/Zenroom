load ../bats_setup
load ../bats_zencode
SUBDOC=time

@test "import time" {
    cat <<EOF | save_asset import_times.data.json
{
  "time_small": 2000,
  "real_timestamp": 1701865412,
  "time_in_dict": {
    "iat": 1701865412,
    "exp": 1901865412,
    "this_is_float": 50000
  }
}
EOF
    cat <<EOF | zexe import_times.zen import_times.data.json
Given I have a 'time' named 'time_small'
Given I have a 'string dictionary' named 'time_in_dict'
Given I have a 'time' named 'real_timestamp'
and debug
Then print all data
EOF
    save_output 'import_times.out.json'
    assert_output '{"real_timestamp":1701865412,"time_in_dict":{"exp":1901865412,"iat":1701865412,"this_is_float":50000},"time_small":2000}'
}

@test "create time" {
    cat <<EOF | zexe create_time.zen
Given nothing
When I create the timestamp
Then print all data
EOF
}


@test "import time grater than 2147483647" {
    cat <<EOF | save_asset time_too_big.data.json
{
  "time_string": "1709303629395",
  "time_number": 1709303629395
}
EOF
    cat <<EOF | save_asset time_too_big_string.zen time_too_big.data.json
Given I have a 'time' named 'time_string'
Then print the data
EOF
    cat <<EOF | save_asset time_too_big_number.zen time_too_big.data.json
Given I have a 'time' named 'time_number'
Then print the data
EOF

    run $ZENROOM_EXECUTABLE -z -a time_too_big.data.json time_too_big_string.zen
    assert_line --partial 'Could not read unix timestamp 1709303629395 out of range'
    run $ZENROOM_EXECUTABLE -z -a time_too_big.data.json time_too_big_number.zen
    assert_line --partial 'Could not read unix timestamp 1.709304e+12'
}

@test "time to integer" {
    cat <<EOF | save_asset intr_from_time.data.json
{
    "string_dictionary": {
        "time": 1709303629
    }
}
EOF
    cat <<EOF | zexe intr_from_time.zen intr_from_time.data.json
Given I have a 'string dictionary' named 'string_dictionary'

When I pickup from path 'string_dictionary.time'
and I create integer 'int_from_dict' cast of timestamp 'time'

When I create timestamp
and I create integer 'int_from_timestamp' cast of timestamp 'timestamp'

Then print the data
EOF
    save_output intr_from_time.out.json
    assert_output --partial '{"int_from_dict":"1709303629","int_from_timestamp":'
}
