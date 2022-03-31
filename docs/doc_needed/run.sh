#!/usr/bin/env bash

# IMPORTANT: the binary file of zenroom has to be in zenroom/src/

# create the file needed to store the data
>introspection.json
>documented.txt

# taking all the zencode statements divided by scenario to easily track them later
count=0 #count the number of scenarios
echo -n "loading statements: ..." 
for i in `ls ../../src/lua/zencode_*`; do
    ../../src/zenroom -D `echo $i | cut -d _ -f 2 | cut -d . -f 1`  2>/dev/null \
	| jq .  > temp.json;
    count=$((count+1))
    scenario=`jq ".Scenario" temp.json`
    cat temp.json \
	| jq '.["Given", "If", "When", "Then"] | keys[] ' \
	| sed -e 's/\\\"/\"/g' -e 's/^.//g' -e 's/.$//g' \
	| jq -R -s 'split("\n") ' \
	| jq "{$scenario : . }" >> introspection.json
done
rm -f temp.json

echo 
echo "-----------------------------------------------"
echo "      all the statements have been loaded      "
echo "-----------------------------------------------"
echo

# taking all the documented statements till now
echo -n "loading documented statements: ... "
for i in ../_media/examples/zencode_cookbook/**/*.zen; do
    cat $i \
	| sed 's/^[ \t]*//' \
	| grep "^Given\|^given\|^If\|^if\|^When\|^when\|^Then\|^then\|^And\|^and" >> documented.txt
done
for i in ../_media/examples/zencode_cookbook/*.zen; do
    cat $i \
	| sed 's/^[ \t]*//' \
	| grep "^Given\|^given\|^If\|^if\|^When\|^when\|^Then\|^then\|^And\|^and" >> documented.txt
done

echo
echo "-----------------------------------------------"
echo "  all documented statements have been loaded   "
echo "-----------------------------------------------"
echo

# lua program that write on the file to_be_documented.txt the statements
# that are not documented yet divided by scenario
lua doc_control.lua introspection.json documented.txt
rm -f introspection.json documented.txt
echo
echo "-----------------------------------------------"
echo "  all statements to be documented can be found "
echo "        in to_be_documented.txt file           "
echo "-----------------------------------------------"
echo

lines=`wc -l < to_be_documented.txt`

if [[ $lines -gt $count ]]
then
    to_be_doc=$((lines-count))
    echo "There are ${to_be_doc} statements to be documented"
    exit 1
fi
