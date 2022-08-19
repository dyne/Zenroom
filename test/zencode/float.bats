load ../bats_setup
load ../bats_zencode
SUBDOC=float

@test "import float" {
    cat <<EOF | save_asset import_floats.data
{
  "fp_number": 3.5,
  "fp_str": "3.5",
  "fp_int": "3",
  "stringa": "3.5",
  "int_str": "100000000000000000000",
  "int_number": 10000,
}
EOF
    cat <<EOF | zexe import_floats.zen import_floats.data
Given I have a 'float' named 'fp_number'
Given I have a 'float' named 'fp_str'
Given I have a 'float' named 'fp_int'
Given I have a 'string' named 'stringa'
Given I have a 'integer' named 'int_str'
Given I have a 'integer' named 'int_number'
and debug

Then print all data
EOF
    save_output 'import_floats.json'
    assert_output '{"fp_int":3,"fp_number":3.5,"fp_str":3.5,"int_number":10000,"int_str":"100000000000000000000","stringa":"3.5"}'
}

@test 'import float as int' {
    skip 'could not assert failure'
cat <<EOF | save_asset wrong_int.data
{
  "int_fp": 100.5
}
EOF
cat <<EOF | zexe wrong_int.zen wrong_int.data
Given I have a 'integer' named 'int_fp'
and debug

Then print all data
EOF
    assert_failure


}

@test 'import float from non numeric string' {
    skip 'could not assert failure'
    cat <<EOF | save_asset wrong_float.json
{
  "fp_str": "hello world"
}
EOF
    cat <<EOF | zexe wrong_float.zen wrong_float.json
Given I have a 'float' named 'fp_str'
and debug

Then print all data
EOF
    assert_failure
}
