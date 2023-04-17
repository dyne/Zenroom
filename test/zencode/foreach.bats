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
When I create the new array
Foreach 'x' in 'xs'
If I verify number 'x' is less than 'limit'
When I move 'x' in 'new array'
Endif
EndForeach
When I rename 'new array' to 'new nums'
Then print 'new nums' as 'string'
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
When I create the new array
Foreach 'x' in sequence from 'zero' to 'limit' with step 'one'
When I move 'x' in 'new array'
EndForeach
When I rename 'new array' to 'new strings'
Then print 'new strings' as 'string'
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
When I create the new array
Foreach 'x' in sequence from 'zero' to 'limit' with step 'one'
When I move 'x' in 'new array'
EndForeach
Then print 'new array' as 'string'
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
When I create the new array
When I rename 'new array' to 'new nums'
When I create the new array
When I rename 'new array' to 'old keys'
When I create the 'string dictionary'
When I rename 'string dictionary' to 'ifdict'
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
Then print 'new nums' as 'string'
Then print 'ifdict' as 'string'
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

