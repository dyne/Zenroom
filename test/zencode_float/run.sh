#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | save float import_floats.json
{
  "fp_number": 3.5,
  "fp_str": "3.5",
  "fp_int": "3",
  "stringa": "3.5",
  "int_str": "100000000000000000000",
  "int_number": 10000,
}
EOF
cat <<EOF | debug import_floats.zen -a import_floats.json
Given I have a 'float' named 'fp_number'
Given I have a 'float' named 'fp_str'
Given I have a 'float' named 'fp_int'
Given I have a 'string' named 'stringa'
Given I have a 'integer' named 'int_str'
Given I have a 'integer' named 'int_number'
and debug

Then print all data
EOF


# The following should fail
# cat <<EOF | save float wrong_int.json
# {
  # "int_fp": 100.5
# }
# EOF
# cat <<EOF | debug wrong_int.zen -a wrong_int.json
# Given I have a 'integer' named 'int_fp'
# and debug
#
# Then print all data
# EOF

# The following should fail
# cat <<EOF | save float wrong_float.json
# {
  # "fp_str": "hello world"
# }
# EOF
# cat <<EOF | debug wrong_float.zen -a wrong_float.json
# Given I have a 'float' named 'fp_str'
# and debug
#
# Then print all data
# EOF
#

