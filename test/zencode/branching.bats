load ../bats_setup
load ../bats_zencode
SUBDOC=branching

@test "Number comparison" {
    cat << EOF | save_asset number_comparison.json
{ "number_lower": 10,
  "number_higher": 50
}
EOF

    cat << EOF | zexe number_comparison.zen number_comparison.json
# Here we're loading the two numbers we have just defined
Given I have a 'number' named 'number_lower'
and I have a 'number' named 'number_higher'

# Here we try a simple comparison between the numbers
# if the condition is satisfied, the 'When' and 'Then' statements
# in the rest of the branch will be executed, which is not the case here.
If number 'number_lower' is more than 'number_higher'
When I create the random 'random_left_is_higher'
Then print string 'number_lower is higher'
Endif

# A simple comparison where the condition is satisfied, the 'When' and 'Then' statements are executed.
If number 'number_lower' is less than 'number_higher'
When I create the random 'just a random'
Then print string 'I promise that number_higher is higher than number_lower'
Endif

# We can also check if a certain number is less than or equal to another one
If number 'number_lower' is less or equal than 'number_higher'
Then print string 'the number_lower is less than or equal to number_higher'
Endif
# or if it is more than or equal to
If number 'number_lower' is more or equal than 'number_higher'
Then print string 'the number_lower is more than or equal to number_higher, imposssible!'
Endif

# Here we try a nested comparison: if the first condition is
# satisfied, the second one is evaluated too. Given the conditions,
# they can't both be true at the same time, so the rest of the branch won't be executed.
If number 'number_lower' is less than 'number_higher'
If I verify 'number_lower' is equal to 'number_higher'
When I create the random 'random_this_is_impossible'
Then print string 'the conditions can never be satisfied'
Endif

# You can also check if an object exists at a certain point of the execution, with the statement:
# If 'objectName' is found
If 'just a random' is found
Then print string 'I found the newly created random number, so I certify that the condition is satisfied'
Endif

When I create the random 'just a random in the main branch'
Then print all data
EOF

    save_output "number_comparison.json"
    assert_output '{"just_a_random":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","just_a_random_in_the_main_branch":"VyJ47aH6+hysFuthAZJP+LyFxmZs6L56Ru0P+JlCbDs=","number_higher":50,"number_lower":10,"output":["I_promise_that_number_higher_is_higher_than_number_lower","the_number_lower_is_less_than_or_equal_to_number_higher","I_found_the_newly_created_random_number,_so_I_certify_that_the_condition_is_satisfied"]}'
}

@test "Complex comparison" {
    cat << EOF | save_asset complex_comparison.json
{ "string_hello": "hello",
  "string_world": "world",
  "dictionary_equal" : { "1": "hello",
                         "2": "hello",
                         "3": "hello" },
  "dictionary_not_equal": { "1": "hello",
                            "2": "hello",
                            "3": "world" }
}
EOF

    cat << EOF | zexe complex_comparison.zen complex_comparison.json
# Here we're loading the two strings and the two arrays we have just defined
Given I have a 'string' named 'string_hello'
Given I have a 'string' named 'string_world'
Given I have a 'string dictionary' named 'dictionary_equal'
Given I have a 'string dictionary' named 'dictionary_not_equal'

# Here we try a simple comparison between the strings
If I verify 'string_hello' is equal to 'string_world'
Then print string 'string_hello is equal to string_world, impossible!'
Endif

# Here we try a simple comparison between the strings
If I verify 'string_hello' is not equal to 'string_world'
Then print string 'string_hello is not equal to string_world'
Endif

# Here we compare a string with an element of the dictionary
If I verify 'string_hello' is equal to '1' in 'dictionary equal'
Then print string 'string_hello is equal to the element with key equal to 1 in dictionary_equal'
Endif
If I verify 'string_hello' is not equal to '1' in 'dictionary equal'
Then print string 'string_hello is not equal to the element with key equal to 1 in dictionary_equal, impossible!'
Endif

# Here we check if all the elements in the dictionary are equal
# (it works also with arrays)
If the elements in 'dictionary_equal' are equal
Then print string 'all elements inside dictionary_equal are equal'
Endif

# Here we check if at least two elements in the dictionary are different
# (it works also with arrays)
If the elements in 'dictionary_not_equal' are not equal
Then print string 'all elements inside dictionary_not_equal are different'
Endif

EOF
    save_output "complex_comparison.json"
    assert_output '{"output":["string_hello_is_not_equal_to_string_world","string_hello_is_equal_to_the_element_with_key_equal_to_1_in_dictionary_equal","all_elements_inside_dictionary_equal_are_equal","all_elements_inside_dictionary_not_equal_are_different"]}'
}

@test "" {
    cat << EOF | save_asset leftrightB.json
{ "left": 60,
  "right": 50 }
EOF

    cat << EOF | zexe branchB.zen leftrightB.json
Given I have a 'number' named 'left'
and I have a 'number' named 'right'

If number 'left' is less than 'right'
and I verify 'right' is equal to 'right'
Then print string 'right is higher'
and print string 'and I am right'
endif

If number 'left' is more than 'right'
Then print string 'left is higher'
endif
EOF
    save_output "branchB.json"
    assert_output '{"output":["left_is_higher"]}'
}
