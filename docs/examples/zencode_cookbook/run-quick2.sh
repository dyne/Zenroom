
Z=zenroom
n=0
tmp=`mktemp`


cat <<EOF | tee givenLoadNumber.zen | $Z -z -a myFlatObject.json | tee givenLoadNumberOutput.json
Given I have a number in 'myNumber'
Then print all data
EOF
