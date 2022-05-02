# this file create the zencode_utterances_reworked.yaml file
# that in turn is used by zencode-list.md to document all the
# zenroom statements

rm -f zencode_utterances_reworked.yaml

for i in `ls ../../src/lua/zencode_*`; do
    SCENARIO=`echo $i | cut -d _ -f 2 | cut -d . -f 1`
    ../../src/zenroom -D $SCENARIO  2>/dev/null | jq .  > temp.json;
    echo "### [${SCENARIO}]" >> zencode_utterances_reworked.yaml
    if [ $SCENARIO == "debug" ]; then
	cat temp.json \
	    | jq '."Given" | keys[] ' \
	    | sed -e 's/\\\"/\"/g' -e 's/^.//g' -e 's/.$//g'  \
	    | sort \
		  >> zencode_utterances_reworked.yaml
    else
	cat temp.json \
	    | jq '.["Given", "If", "When", "Then"] | keys[] ' \
	    | sed -e 's/\\\"/\"/g' -e 's/^.//g' -e 's/.$//g'  \
	    | sort \
		  >> zencode_utterances_reworked.yaml
    fi
    echo "### [${SCENARIO}]" >> zencode_utterances_reworked.yaml
done

rm temp.json
