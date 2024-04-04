load ../bats_setup
load ../bats_zencode
SUBDOC=foreach

@test "Simplest loop ever" {
    cat << EOF | save_asset verysimple.data
{
  "xs": ["a", "b"]
}
EOF

    cat << EOF | zexe verysimple.zen verysimple.data
Given I have a 'string array' named 'xs'
When I create the new array
Foreach 'x' in 'xs'
When I move 'x' in 'new array'
EndForeach
Then print 'new array' as 'string'
EOF
    save_output "very_simple.out"
    assert_output '{"new_array":["a","b"]}'
}

@test "Simple foreach in if" {
    cat << EOF | save_asset foreach_in_if.data
{
  "xs": [1,2,3,4,5,6,7,8,9],
  "one": 1,
  "limit": 6
}
EOF

    cat << EOF | zexe foreach_in_if.zen foreach_in_if.data
Given I have a 'float array' named 'xs'
Given I have a 'float' named 'one'
Given I have a 'float' named 'limit'
When I create the new array
If I verify number 'one' is less than 'limit'
Foreach 'x' in 'xs'
When I move 'x' in 'new array'
EndForeach
Foreach 'x' in 'xs'
When I move 'x' in 'new array'
EndForeach
When I write string 'ciccio' in 'ciccio'
Foreach 'x' in 'xs'
When I move 'x' in 'new array'
EndForeach
Endif
Then print 'new array' as 'string'
EOF
    save_output "foreach_in_if.out"
    assert_output '{"new_array":[1,2,3,4,5,6,7,8,9,1,2,3,4,5,6,7,8,9,1,2,3,4,5,6,7,8,9]}'
}


@test "Simple if in foreach" {
    cat << EOF | save_asset if_in_foreach.data
{
  "xs": [1,2,3,4,5,6,7,8,9],
  "limit": 6
}
EOF

    cat << EOF | zexe if_in_foreach.zen if_in_foreach.data
Given I have a 'float array' named 'xs'
Given I have a 'float' named 'limit'
When I create the 'float array' named 'new array'
Foreach 'x' in 'xs'
If I verify number 'x' is less than 'limit'
When I move 'x' in 'new array'
Endif
EndForeach
When I rename 'new array' to 'new nums'
Then print 'new nums'
EOF
    save_output "if_in_foreach.out"
    assert_output '{"new_nums":[1,2,3,4,5]}'
}

@test "Foreach with floats" {
    cat << EOF | save_asset foreach_float.data
{
  "zero": 0,
  "one": 2,
  "limit": 11
}
EOF

    cat << EOF | zexe foreach_float.zen foreach_float.data
Given I have a 'float' named 'zero'
Given I have a 'float' named 'one'
Given I have a 'float' named 'limit'
When I create the 'float array' named 'new array'
Foreach 'x' in sequence from 'zero' to 'limit' with step 'one'
When I move 'x' in 'new array'
EndForeach
When I rename 'new array' to 'new strings'
Then print 'new strings'
EOF
    save_output "foreach_float.out"
    assert_output '{"new_strings":[0,2,4,6,8,10]}'
}

@test "Foreach with bigs" {
    cat << EOF | save_asset foreach_big.data
{
  "zero": "-5",
  "one": "2",
  "limit": "11"
}
EOF

    cat << EOF | zexe foreach_big.zen foreach_big.data
Given I have a 'integer' named 'zero'
Given I have a 'integer' named 'one'
Given I have a 'integer' named 'limit'
When I create the 'integer array' named 'new array'
Foreach 'x' in sequence from 'zero' to 'limit' with step 'one'
When I move 'x' in 'new array'
EndForeach
Then print 'new array'
EOF
    save_output "foreach_big.out"
    assert_output '{"new_array":["-5","-3","-1","1","3","5","7","9","11"]}'
}

@test "Foreach with append string" {
    cat << EOF | save_asset foreach_append.data
{
  "zero": "-5",
  "one": "2",
  "limit": "11",
}
EOF

    cat << EOF | zexe foreach_append.zen foreach_append.data
Given I have a 'integer' named 'zero'
Given I have a 'integer' named 'one'
Given I have a 'integer' named 'limit'
When I write string '' in 'result'
Foreach 'x' in sequence from 'zero' to 'limit' with step 'one'
When I append 'x' to 'result'
EndForeach
Then print 'result'
EOF
    save_output "foreach_append.out"
    assert_output '{"result":"-5-3-11357911"}'
}

@test "Foreach with a lot of statements" {
    cat << EOF | save_asset foreach_append.data
{
  "numbers": ["42","37","55","78"],
  "const": "20",
  "limit": "2",
  "counter": 0
}
EOF

    cat << EOF | zexe foreach_append.zen foreach_append.data
Given I have a 'integer array' named 'numbers'
Given I have a 'integer' named 'const'
Given I have a 'float' named 'counter'
Given I have a 'integer' named 'limit'
When I create the 'integer array' named 'new nums'
When I create the new array
When I rename 'new array' to 'old keys'
When I create the 'integer dictionary' named 'ifdict'
When I set 'resultname' to 'result' as 'string'
Foreach 'x' in 'numbers'
When I create the result of '(x + 12) / const'
When I copy 'result' to 'result in array'
# some comments
# some comments
# some comments
# some comments
If I verify number 'limit' is less than 'x'
When I set 'keyname' to 'key' as 'string'
When I append 'x' to 'keyname'
Endif
When I move 'result in array' in 'new nums'
If I verify number 'limit' is less than 'x'
When I rename the object named by 'resultname' to named by 'keyname'
Endif
If I verify number 'limit' is less than 'x'
When I move named by 'keyname' in 'ifdict'
Endif
When I remove 'keyname'
# some comments
# some comments
# some comments
EndForeach
Then print 'new nums'
Then print 'ifdict'
EOF
    save_output "foreach_append.out"
    assert_output '{"ifdict":{"key37":"2","key42":"2","key55":"3","key78":"4"},"new_nums":["2","2","3","4"]}'
}

@test "Zip foreach" {
    cat << EOF | save_asset foreach_zip.data
{
  "numbers": ["42","37","55","78"],
  "labels": ["pippo", "pluto", "paperino"],
  "from": "-11",
  "to": "10",
  "step": "4"
}
EOF

    cat << EOF | zexe foreach_zip.zen foreach_zip.data
Given I have a 'integer array' named 'numbers'
Given I have a 'string array' named 'labels'
Given I have a 'integer' named 'from'
Given I have a 'integer' named 'to'
Given I have a 'integer' named 'step'
When I create the 'integer dictionary'
When I rename 'integer dictionary' to 'zipdict'
When I set 'result name' to 'result' as 'string'
Foreach 'x' in 'numbers'
Foreach 'i' in sequence from 'from' to 'to' with step 'step'
Foreach 'label' in 'labels'
When I create the result of 'i * x'
When I rename the object named by 'result name' to named by 'label'
When I move named by 'label' in 'zipdict'
# some comments
# some comments
# some comments
EndForeach
Then print 'zipdict' as 'integer'
EOF
    save_output "foreach_zip.out"
    assert_output '{"zipdict":{"paperino":"-165","pippo":"-462","pluto":"-259"}}'
}

@test "Nested if in foreach" {
    cat << EOF | save_asset foreach_nestedif.data
{
  "numbers":  [1,2,3,4,5,6,7,8],
  "numbers2": [10,9,8,7,6,5,4,3,2,1,0,-1],
  "limit": 4,
  "zero": 0
}
EOF

    cat << EOF | zexe foreach_nestedif.zen foreach_nestedif.data
Given I have a 'float array' named 'numbers'
Given I have a 'float array' named 'numbers2'
Given I have a 'float' named 'limit'
Given I have a 'float' named 'zero'
When I create the 'float array'
When I rename 'float array' to 'floats'
Foreach 'x' in 'numbers'
Foreach 'y' in 'numbers2'
If I verify number 'x' is more than 'limit'
If I verify number 'y' is more than 'limit'
When I move 'x' in 'floats'
endif
EndForeach
If I verify number 'zero' is less than 'limit'
If I verify number 'zero' is less than 'limit'
Foreach 'a' in 'numbers'
Foreach 'b' in 'numbers2'
When I move 'b' in 'floats'
EndForeach
endif
Then print 'floats'
EOF
    save_output "foreach_nestedif.out"
    assert_output '{"floats":[5,6,10,9,8,7,6,5,4,3]}'
}

@test "exit from foreach loop" {
    cat << EOF | save_asset exit_from_foreach.data
{
  "numbers":  [1,2,3,4,5,6,7,8],
  "limit": 4,
  "zero": 0,
  "two": 2,
  "ten": 10
}
EOF

    cat << EOF | zexe exit_from_foreach.zen exit_from_foreach.data
Given I have a 'float array' named 'numbers'
Given I have a 'float' named 'limit'
Given I have a 'float' named 'zero'
Given I have a 'float' named 'two'
Given I have a 'float' named 'ten'

When I create the 'float array' named 'y'
Foreach 'x' in 'numbers'
If I verify 'x' is equal to 'limit'
When I break foreach
EndIf
When I move 'x' in 'y'
EndForeach

If I verify 'x' is found
When I remove 'x'
EndIf

When I create the 'float array' named 'z'
Foreach 'x' in sequence from 'zero' to 'ten' with step 'two'
If I verify 'x' is equal to 'limit'
When I exit foreach
EndIf
When I copy 'x' in 'z'
EndForeach

Then print 'y'
Then print 'z'
EOF
    save_output "exit_from_foreach.out"
    assert_output '{"y":[1,2,3],"z":[0,2]}'
}

@test "Two foreach with the same iterator variable name" {
    cat << EOF | save_asset two_foreach_same_var.data
{
    "arr1": [
        "str1",
        "str2"
    ],
    "arr2": [
        "str3"
    ]
}
EOF
    cat << EOF | zexe two_foreach_same_var.zen two_foreach_same_var.data
Given I have a 'string array' named 'arr1'
Given I have a 'string array' named 'arr2'

When I create the 'string array' named 'res'
Foreach 'x' in 'arr1'
When I copy 'x' in 'res'
Endforeach

Foreach 'x' in 'arr2'
When I copy 'x' in 'res'
Endforeach

Then print the 'res'
EOF
    save_output two_foreach_same_var.out
    assert_output '{"res":["str1","str2","str3"]}'
}

@test "Foreach on array of schema" {
    cat << EOF | save_asset foreach_schema.data
{
    "arr": [
        "eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbInZucGt1cWZBSWFBTlBmZXl6WXhUVllWUGxJY3JBWlVvU3N5TGFhQ0tlWUkiLCAiM1BEeUhOMXphcklJMG1TdDUwMkV2ZVIwVHhlOHlTQ1hDOFlYd1NvV1lZWSIsICJFMS12Wnl1Wmhlbkhlam1nYi1kTFhtaDBPODFLTUtWU25RYjN2Mjl6SGlRIl0sICJfc2RfYWxnIjogInNoYS0yNTYiLCAiaXNzIjogImh0dHA6Ly9leGFtcGxlLm9yZyIsICJzdWIiOiAidXNlciA0MiJ9.-BY5L0dcz2p-nCIhmL_0RK5QjzmKOI45E7anmZqg0Vct16lyF2_em3R8GzewmcrVT-NnZaT6EKrO79F4VGkFeQ~WyJ1eURGMUgwQVlSYmI0TVFubUx2dmVBIiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyJWam9zM2ZoOFZVU3Z2NHVYUVhuSWlRIiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyIzV2JpbGZtNk1rdDFBUzlERXFtOS1nIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~",
        "eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbIlVaNG1MUV9MWUQ3QWc5RlpBSWMzX0Iyd0ZPR29DdlpBRGg1X2V4U3VHWUUiLCAibGM4bFZmT0ZMaXFSUU80T2lHeTFJWEh5SmpMT0dRSFY3c094eEQ0N1MySSIsICItYkIyZTVVdVZQZEltMzRWWVVpU2FfRHFJV1Ytc2tWSVphUl96MVNwYmFnIiwgInNkT0RjeXdEcVFVaVVnREV5UERyWFZaNTdkeEswNVhoZG5DWFhRRTlOX2ciXSwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJpc3MiOiAiaHR0cDovL2V4YW1wbGUub3JnIiwgInN1YiI6ICJ1c2VyIDQyIn0.tZRB6X7fgASuHmPrhpIK_4veA6c2Ue0g3xGxIrPjHBsWXeROpAEmvMn593x5zkenuvRoO2r2wZNxnHJhqu0l0Q~WyJ0Tm9iM0NBTVhMcUVQWXRBWHBuVmdBIiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ~WyJCbndnQThSODAtYUJtUVpuUzlrSnZnIiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd~WyJhOVA3bENDZHVnNEZXWG95b21FWHZ3IiwgImFkZHJlc3MiLCB7ImNvdW50cnkiOiAiVVMiLCAibG9jYWxpdHkiOiAiQW55dG93biIsICJyZWdpb24iOiAiQW55c3RhdGUiLCAic3RyZWV0X2FkZHJlc3MiOiAiMTIzIE1haW4gU3QifV0~WyJJcURNYkUzeEtVOXAtOXlRTDVKN01BIiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0~"
    ]
}
EOF
    cat << EOF | zexe foreach_schema.zen foreach_schema.data
Scenario 'sd_jwt' : sd_jwt

Given I have a 'signed_selective_disclosure array' named 'arr'

Foreach 'x' in 'arr'
When I rename 'x' to 'res'
and I break the foreach
Endforeach

Then print the 'res'
EOF
    save_output foreach_schema.out
    assert_output '{"res":"eyJhbGciOiAiRVMyNTYiLCAidHlwIjogInZjK3NkLWp3dCJ9.eyJfc2QiOiBbInZucGt1cWZBSWFBTlBmZXl6WXhUVllWUGxJY3JBWlVvU3N5TGFhQ0tlWUkiLCAiM1BEeUhOMXphcklJMG1TdDUwMkV2ZVIwVHhlOHlTQ1hDOFlYd1NvV1lZWSIsICJFMS12Wnl1Wmhlbkhlam1nYi1kTFhtaDBPODFLTUtWU25RYjN2Mjl6SGlRIl0sICJfc2RfYWxnIjogInNoYS0yNTYiLCAiaXNzIjogImh0dHA6Ly9leGFtcGxlLm9yZyIsICJzdWIiOiAidXNlciA0MiJ9.-BY5L0dcz2p-nCIhmL_0RK5QjzmKOI45E7anmZqg0Vct16lyF2_em3R8GzewmcrVT-NnZaT6EKrO79F4VGkFeQ~WyJ1eURGMUgwQVlSYmI0TVFubUx2dmVBIiwgImdpdmVuX25hbWUiLCAiSm9obiJd~WyJWam9zM2ZoOFZVU3Z2NHVYUVhuSWlRIiwgImZhbWlseV9uYW1lIiwgIkRvZSJd~WyIzV2JpbGZtNk1rdDFBUzlERXFtOS1nIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ~"}'
}
