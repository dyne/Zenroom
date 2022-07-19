#!/usr/bin/env bash

SUBDOC=branching

DEBUG=1
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

set -e

cat << EOF | save $SUBDOC number_comparison.json
{ "number_lower": 10,
  "number_higher": 50
}
EOF

cat << EOF | zexe number_comparison.zen -a number_comparison.json | save $SUBDOC number_comparison_output.json
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

cat << EOF | save $SUBDOC complex_comparison.json
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

cat << EOF | zexe complex_comparison.zen -a complex_comparison.json | save $SUBDOC complex_comparison_output.json
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
exit 0
cat << EOF | save $SUBDOC leftrightB.json
{ "left": 60,
  "right": 50 }
EOF

cat << EOF | zexe branchB.zen -a leftrightB.json | jq 
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

cat <<EOF | save $SUBDOC found.json
{
	"str": "good",
	"empty_arr": [],
	"not_empty_dict": {
		      "empty_octet":""
		      },
	"arr": ["hello",
		"goodmorning",
		"hi",
		"goodevening"],
	"dict": {
		"hello": "world",
		"nice": "world",
		"big": "world"
		}
}
EOF


cat << EOF | zexe found.zen -a found.json | jq .
Given I have a 'string dictionary' named 'dict'
Given I have a 'string array' named 'arr'
Given I have a 'string dictionary' named 'not_empty_dict'
Given I have a 'string array' named 'empty_arr'
Given I have a 'string' named 'str'

When I create the 'string array' named 'found output'

If 'str' is found
When I insert string '1.success' in 'found output'
EndIf

If 'empty_arr' is found
When I insert string '2.success' in 'found output'
EndIf

If 'hello' is not found
When I insert string '3.success' in 'found output'
EndIf

If 'hello' is found in 'arr'
When I insert string '4.success' in 'found output'
EndIf

If 'hello' is found in 'dict'
When I insert string '5.success' in 'found output'
EndIf

If 'good' is not found in 'arr'
When I insert string '6.success' in 'found output'
EndIf

If 'good' is not found in 'dict'
When I insert string '7.success' in 'found output'
EndIf

If 'empty octet' is not found in 'not_empty_dict'
When I insert string '8.success' in 'found output'
EndIf


If 'hello' is found
When I insert string '1.fail' in 'found output'
EndIf

If 'str' is not found
When I insert string '2.fail' in 'found output'
EndIf

If 'good' is found in 'arr'
When I insert string '3.fail' in 'found output'
EndIf

If 'good' is found in 'dict'
When I insert string '4.fail' in 'found output'
EndIf

If 'hello' is not found in 'arr'
When I insert string '5.fail' in 'found output'
EndIf

If 'hello' is not found in 'dict'
When I insert string '6.fail' in 'found output'
EndIf

If 'hello' is found in 'empty arr'
When I insert string '7.fail' in 'found output'
EndIf

If 'empty_arr' is not found
When I insert string '8.fail' in 'found output'
EndIf

Then print 'found output'

EOF
