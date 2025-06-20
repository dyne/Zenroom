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

@test "sum and subtraction of timestamps" {
    cat <<EOF | save_asset sum_timestamp.data.json
{
    "exp": 60,
    "timestamp": 1712324515
}
EOF
    cat <<EOF | zexe sum_timestamp.zen sum_timestamp.data.json
Given I have a 'time' named 'exp'
Given I have a 'time' named 'timestamp'

When I create the result of 'timestamp' + 'exp'
and I rename 'result' to 'sum'
When I create the result of 'timestamp' - 'exp'
and I rename 'result' to 'sub'

Then print the 'sum'
and print the 'sub'
EOF
    save_output sum_timestamp.out.json
    assert_output '{"sub":1712324455,"sum":1712324575}'
}

@test "timestamps comparison" {
    cat <<EOF | save_asset timestamp_comparison.data.json
{
    "lower": 60,
    "grater": 1712324515
}
EOF
    cat <<EOF | zexe timestamp_comparison.zen timestamp_comparison.data.json
Given I have a 'time' named 'lower'
Given I have a 'time' named 'grater'

When I verify number 'grater' is more than 'lower'
and I verify number 'lower' is less than 'grater'
and I verify 'grater' is equal to 'grater'
and I verify 'lower' is not equal to 'grater'

Then print the string 'OK'
EOF
    save_output sum_timestamp.out.json
    assert_output '{"output":["OK"]}'
}

@test "timestamp to date table" {
    cat <<EOF | save_asset timestamp_to_date_table.data.json
{
    "timestamp": 0
}
EOF
    cat <<EOF | zexe timestamp_to_date_table.zen timestamp_to_date_table.data.json
    Given I have a 'time' named 'timestamp'

    When I create date table of timestamp 'timestamp'

    Then print the 'date table'
EOF
    save_output timestamp_to_date_table.out.json
    assert_output --regexp '\{"date_table":\{"day":1,"hour":[0-9]+,"isdst":false,"min":0,"month":1,"sec":0,"year":1970\}\}'
}

@test "date table to timestamp" {
    cat <<EOF | zexe date_table_to_timestamp.zen timestamp_to_date_table.out.json
    Given I have a 'date table' named 'date_table'

    When I create timestamp of date table 'date_table'

    Then print the 'timestamp'
EOF
    save_output date_table_to_timestamp.out.json
    assert_output '{"timestamp":0}'
}

@test "failing date table to timestamp" {
    cat <<EOF | save_asset fail_date_table_to_timestamp.data.json
{
    "date_table": {
        "year": 3
    }
}
EOF
    cat <<EOF | save_asset fail_date_table_to_timestamp.zen
    Given I have a 'date table' named 'date_table'

    When I create timestamp of date table 'date_table'

    Then print the 'timestamp'
EOF
    run $ZENROOM_EXECUTABLE -z -a fail_date_table_to_timestamp.data.json fail_date_table_to_timestamp.zen
    assert_line --partial 'Date table date_table can not be converted to timestamp, 3 < 1970'
}

@test "sum of date tables and timestamp" {
    cat <<EOF | save_asset sum_of_date_table.data.json
{
    "date_table": {
        "year": 1,
        "month": 1,
        "day": 5
    },
    "another_date_table": {
        "year": 25000,
        "moth": 3,
        "day": 20,
        "sec": 200
    },
    "timestamp": 0,
    "another_timestamp": 1712324515
}
EOF
    cat <<EOF | zexe sum_of_date_table.zen sum_of_date_table.data.json
    Given I have a 'date table' named 'date_table'
    Given I have a 'date table' named 'another_date_table'
    Given I have a 'time' named 'timestamp'
    Given I have a 'time' named 'another_timestamp'

    When I create the result of 'date_table' + 'another_date_table'
    and I rename 'result' to 'sum_of_date_tables'

    When I create the result of 'timestamp' + 'another_timestamp'
    and I rename 'result' to 'sum_of_timestamp'

    When I create the result of 'date_table' + 'timestamp'
    and I rename 'result' to 'sum_of_date_table_and_timestamp'

    When I create the result of 'timestamp' + 'date_table'
    and I rename 'result' to 'sum_of_timestamp_and_date_table'

    When I verify 'sum_of_timestamp_and_date_table' is equal to 'sum_of_date_table_and_timestamp'

    When I create the result of 'another_date_table' + 'another_timestamp'
    and I rename 'result' to 'sum_of_timestamp_and_another_date_table'

    Then print the 'sum_of_timestamp_and_another_date_table'
    Then print the 'sum_of_timestamp_and_date_table'
    Then print the 'sum_of_date_table_and_timestamp'
    Then print the 'sum_of_timestamp'
    Then print the 'sum_of_date_tables'
EOF
    save_output sum_of_date_table.out.json
    assert_output --regexp '\{"sum_of_date_table_and_timestamp":\{"day":6,"hour":[0-9]+,"min":0,"month":2,"sec":0,"year":1971\},"sum_of_date_tables":\{"day":25,"hour":0,"min":0,"month":1,"sec":200,"year":25001\},"sum_of_timestamp":1712324515,"sum_of_timestamp_and_another_date_table":\{"day":25,"hour":[0-9]+,"min":41,"month":4,"sec":255,"year":27024\},"sum_of_timestamp_and_date_table":\{"day":6,"hour":[0-9]+,"min":0,"month":2,"sec":0,"year":1971\}\}'
}

@test "utc time" {
    cat <<EOF | save_asset utc_time.data.json
{
    "fixed_timestamp": "1745568429"
}
EOF
    cat <<EOF | zexe utc_time.zen utc_time.data.json
Given I have a 'time' named 'fixed_timestamp'

When I create the UTC timestamp of now
and I rename 'UTC_timestamp' to 'utc_now'
When I create the UTC timestamp of 'fixed_timestamp'
and I rename 'UTC_timestamp' to 'utc_fixed'

When I create timestamp of UTC timestamp 'utc_fixed'
When I verify 'fixed_timestamp' is equal to 'timestamp'

Then print the 'utc_now'
and print the 'utc_fixed'
and print the 'timestamp'
EOF
    save_output utc_time.out.json
    assert_output --regexp '\{"timestamp":1745568429,"utc_fixed":"2025-04-25T08:07:09Z","utc_now":"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"\}'
}
