load ../bats_setup
load ../bats_zencode
SUBDOC=educational

@test "Foreach: display number divisible by 5 from a list following also other conditions" {
    cat << EOF | save_asset foreach_divisible_by_five.data.json
{
    "numbers": [12, 75, 150, 180, 145, 525, 50]
}
EOF
     cat << EOF | save_asset foreach_divisible_by_five.keys.json
{
    "0": 0,
    "5": 5,
    "150": 150,
    "500": 500
}
EOF
    cat << EOF | zexe foreach_divisible_by_five.zen foreach_divisible_by_five.data.json foreach_divisible_by_five.keys.json
# Problem:
# display only those numbers from a list that satisfy the following conditions
# 1. The number must be divisible by five
# 2. If the number is greater than 150, then skip it and move to the following number
# 3. If the number is greater than 500, then stop the loop

Given I have a 'number array' named 'numbers'
Given I have a 'number' named '0'
Given I have a 'number' named '5'
Given I have a 'number' named '150'
Given I have a 'number' named '500'

When I create the 'number array' named 'res'

Foreach 'num' in 'numbers'
    # point 3
    If I verify number 'num' is more than '500'
        When I break foreach
    EndIf
    # point 2
    If I verify number 'num' is less or equal than '150'
        When I create the result of 'num' % '5'
        # point 1
        If I verify 'result' is equal to '0'
            When I copy 'num' in 'res'
        EndIf
        When I remove 'result'
    EndIf
EndForeach

Then print the 'res'
EOF
    save_output foreach_divisible_by_five.out.json
    assert_output '{"res":[75,150,145]}'
}


@test "Foreach: list in reverse order" {
    cat << EOF | save_asset foreach_reverse_order.data.json
{
    "list": [10, 20, 30, 40, 50]
}
EOF
    cat << EOF | save_asset foreach_reverse_order.keys.json
{
    "0": 0,
    "1": 1
}
EOF
    cat << EOF | zexe foreach_reverse_order.zen foreach_reverse_order.data.json foreach_reverse_order.keys.json
# Problem:
# reverse the list in input

Given I have a 'number array' named 'list'
Given I have a 'number' named '0'
Given I have a 'number' named '1'

When I create the 'number array' named 'res'

# limit of iteration
When I create the size of 'list'
and I create the result of 'size' - '1'
and I rename 'result' to 'limit'

Foreach 'i' in sequence from '0' to 'limit' with step '1'
    When I create the result of 'size' - 'i'
    and I copy 'result' from 'list' to 'temp'
    and I move 'temp' in 'res'
    and I remove 'result'
EndForeach

Then print 'res'
EOF
    save_output foreach_reverse_order.out.json
    assert_output '{"res":[50,40,30,20,10]}'
}

@test "Foreach: naive list of prime number within a range" {
    cat << EOF | save_asset foreach_naive_prime_in_range.data.json
{
    "start": 25,
    "end": 100
}
EOF
    cat << EOF | save_asset foreach_naive_prime_in_range.keys.json
{
    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6
}
EOF
    cat << EOF | zexe foreach_naive_prime_in_range.zen foreach_naive_prime_in_range.data.json foreach_naive_prime_in_range.keys.json
# Problem:
# print all prime numbers in a range
# Note:
# this is just for educational purpose, there are better method that are not just check if the
# the number is divisible for all the numbers in the range (2, n/2)

Given I have a 'number' named 'start'
Given I have a 'number' named 'end'
Given I have a 'number' named '0'
Given I have a 'number' named '1'
Given I have a 'number' named '2'
Given I have a 'number' named '3'
Given I have a 'number' named '4'
Given I have a 'number' named '5'
Given I have a 'number' named '6'

When I create the 'number array' named 'res'

If I verify number 'start' is more than 'end'
    When I exit with error message 'star must be less than end'
EndIf

# In zenroom when we try to do a foreach where the start is less than the end
# an error is thrown, thus since the inner loop start from 2, the end, that is the
# floor of n/2, should be at least 3 thus n should start from 6.
# Thus this if here take into considerations the prime number before 6 and if they
# are in the range, they are added
If I verify number 'end' is more or equal than '2'
    If I verify number 'start' is less or equal than '2'
        When I copy '2' in 'res'
    EndIf
EndIf
If I verify number 'end' is more or equal than '3'
    If I verify number 'start' is less or equal than '3'
        When I copy '3' in 'res'
    EndIf
EndIf
If I verify number 'end' is more or equal than '5'
    If I verify number 'start' is less or equal than '5'
        When I copy '5' in 'res'
    EndIf
EndIf

# prime numbers grater than 6
If I verify number 'end' is more than '6'
    If I verify number 'start' is less than '6'
        When I remove 'start'
        and I copy '6' to 'start'
    EndIf
    Foreach 'i' in sequence from 'start' to 'end' with step '1'
        When I create the result of 'i' % '2'
        When I rename 'result' to 'is_even'
        If I verify 'is_even' is equal to '0'
            When I set 'not_prime' to 'true' as 'string'
        EndIf
        If I verify 'is_even' is equal to '1'
            When I create the result of 'i' - '1'
            When I rename 'result' to 'even'
            When I create the result of 'even' / '2'
            When I remove 'even'
            When I rename the 'result' to 'limit'
            Foreach 'j' in sequence from '2' to 'limit' with step '1'
                When I create the result of 'i' % 'j'
                If I verify 'result' is equal to '0'
                    When I set 'not_prime' to 'true' as 'string'
                    When I remove 'result'
                    When I break the foreach
                EndIf
                When I remove 'result'
            EndForeach
            When I remove 'limit'
        EndIf
        If I verify 'not_prime' is not found
            When I copy 'i' in 'res'
        EndIf
        If I verify 'not_prime' is found
            When I remove 'not_prime'
        EndIf
        When I remove 'is_even'
    EndForeach
EndIf

Then print 'res'
EOF
    save_output foreach_prime_in_range.out.json
    assert_output '{"res":[29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97]}'
}

@test "Foreach: less naive list of prime number till a number" {
    cat << EOF | save_asset foreach_less_naive_prime_till_number.data.json
{
    "end": 100
}
EOF
    cat << EOF | save_asset foreach_less_naive_prime_till_number.keys.json
{
    "0": 0,
    "1": 1,
    "2": 2
}
EOF
    cat << EOF | zexe foreach_less_naive_prime_till_number.zen foreach_less_naive_prime_till_number.data.json foreach_less_naive_prime_till_number.keys.json
# Problem:
# print all prime numbers till a certain number 'end'
# Note:
# The total complexity of this algorithm is O((n*sqrt(n))/logn), we are checking only for prime divisors till sqrt(n)

Given I have a 'number' named 'end'

Given I have a 'number' named '0'
Given I have a 'number' named '1'
Given I have a 'number' named '2'

When I create the 'number array' named 'res'

If I verify number 'end' is less or equal than '2'
    When I exit with error message 'end should be grater than 2'
EndIf

When I set 'sqrt' to '1' as 'number'
When I set 'sqrt^2' to '1' as 'number'

If I verify number 'end' is more than '1'
    Foreach 'i' in sequence from '2' to 'end' with step '1'
        If I verify number 'sqrt^2' is less than 'i'
            When I create the result of 'sqrt' + '1'
            and I remove 'sqrt'
            and I rename 'result' to 'sqrt'
            When I create the result of 'sqrt' * 'sqrt'
            and I remove 'sqrt^2'
            and I rename 'result' to 'sqrt^2'
        EndIf
        Foreach 'j' in 'res'
            If I verify number 'j' is more than 'sqrt'
                When I break foreach
            EndIf
            When I create the result of 'i' % 'j'
            If I verify 'result' is equal to '0'
                When I set 'not_prime' to 'true' as 'string'
                When I remove 'result'
                When I break the foreach
            EndIf
            When I remove 'result'
        EndForeach
        If I verify 'not_prime' is not found
            When I copy 'i' in 'res'
        EndIf
        If I verify 'not_prime' is found
            When I remove 'not_prime'
        EndIf
    EndForeach
EndIf

Then print 'res'
EOF
    save_output foreach_less_naive_prime_till_number.out.json
    assert_output '{"res":[2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97]}'
}

@test "Foreach: factorial of given number" {
    cat << EOF | save_asset foreach_factorial.data.json
{
    "number": 5
}
EOF
    cat << EOF | save_asset foreach_factorial.keys.json
{
    "0": 0,
    "1": 1
}
EOF
    cat << EOF | zexe foreach_factorial.zen foreach_factorial.data.json foreach_factorial.keys.json
# Problem:
# calcuate the factorial of 'number'

Given I have a 'number' named 'number'
Given I have a 'number' named '0'
Given I have a 'number' named '1'

When I set 'factorial' to '1' as 'number'

If I verify number 'number' is less than '0'
    When I exit with error message 'factorial exists only for positive number'
EndIf
If I verify number 'number' is more than '1'
    Foreach 'i' in sequence from '1' to 'number' with step '1'
        When I create the result of 'factorial' * 'i'
        When I remove 'factorial'
        When I rename 'result' to 'factorial'
    EndForeach
EndIf

Then print 'factorial'
EOF
    save_output foreach_factorial.out.json
    assert_output '{"factorial":120}'
}
