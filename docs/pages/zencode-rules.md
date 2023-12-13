# Zencode *rules*

Rules in Zencode are directives that influence the whole computation of the script. Rules can be written before or after the 'Scenario' directive(s) but always before the first 'Given' statement


# Rule input/output encode: setting encoding for the whole script

When processing the output, Zenroom will use the own encoding of the object. 
This can be overriden by using the ***Rule output encoding*** statement, for example the line:

[](../_media/examples/zencode_cookbook/rules/output_encoding.zen ':include :type=code gherkin')

will get all the output to be printed as *base58*:

[](../_media/examples/zencode_cookbook/rules/base58_output.json ':include :type=code json')

which may come in handy when working with cryptography.

You can also redefine the input encoding, which would work only with ***schemas*** whose encoding is pre-defined. This will be again useful mostly when working with cryptography. For example the output of the above script can be reloaded into Zenroom like this:

[](../_media/examples/zencode_cookbook/rules/input_encoding.zen ':include :type=code gherkin')

# Rule check version

The ***rule check version*** statement, will validate the script's syntax to make sure it matches the Zencode version stated. Not using the line in the beginning of each script will cause a warning. For example:

[](../_media/examples/zencode_cookbook/rules/check_version.zen ':include :type=code gherkin')


# Rule input number strict

The ***Rule input number strict*** statement will import all numbers, whose type is not explicitly stated (as for example inside a **string dictionary**), as floats. You can use the statement like this:

[](../_media/examples/zencode_cookbook/rules/rule_input_number_strict_dictionaries.zen ':include :type=code gherkin')

with input:

[](../_media/examples/zencode_cookbook/rules/rule_input_number_strict_dictionaries.data ':include :type=code json')

the output will look like:

[](../_media/examples/zencode_cookbook/rules/rule_input_number_strict_dictionaries.out ':include :type=code json')

When this statment is not used numbers whose type is not explicitly stated and that are integers in the range from 1500000000 (included) to 2000000000 (not included) will be imported as time. For exmaple with the same input of above and the following script (only the rule line is removed):

[](../_media/examples/zencode_cookbook/rules/not_rule_input_number_strict_dictionaries.zen ':include :type=code gherkin')

the output will be:

[](../_media/examples/zencode_cookbook/rules/not_rule_input_number_strict_dictionaries.out ':include :type=code json')


# Rule unknown ignore

When parsing a script Zenroom will throw an error in case unkown statements are found.
The ***Rule unknown ignore*** statement will do not throw the error but only at the contidition that the unknown statements are found before the *Given* phase and after the *Then* phase. You can use the statement like this:

[](../_media/examples/zencode_cookbook/rules/unknown_ignore.zen ':include :type=code gherkin')
