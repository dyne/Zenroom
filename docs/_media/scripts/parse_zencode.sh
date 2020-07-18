#!/usr/bin/env zsh
# Parse and print a JSON map of Zencode calls in Given() When() Then()
# that are recognised and order them by section for documentation
#
# requires the zenroom interpreter to be installed in PATH
# and also yq https://github.com/kislyuk/yq
#
R=../src/lua

function _parse() {
    section=$1
    action=$2
    print "$(grep -i ''"${action}"'(' $R/zencode_${section}.lua \
	| cut -d '"' -f2 \
    | jq -Rj '. | { '"${action}"': .}' \
    | jq -s . \
    | jq -j '.| {'"${section}"': .}')"
}

FILE=$1

echo "### [given]" > $FILE
print $(_parse given given) | yq -y . >> $FILE
echo "### [given]" >> $FILE
echo "### [when]" >> $FILE
print $(_parse when when) | yq -y . >> $FILE
echo "### [when]" >> $FILE
echo "### [then]" >> $FILE
print $(_parse then then) | yq -y . >> $FILE
echo "### [then]" >> $FILE
echo "### [simple_when]" >> $FILE
print $(_parse ecdh when) | yq -y . >> $FILE
echo "### [simple_when]" >> $FILE
echo "### [coconut_when]" >> $FILE
print $(_parse coconut when) | yq -y . >> $FILE
echo "### [coconut_when]" >> $FILE
echo "### [dp3t_when]" >> $FILE
print $(_parse dp3t when) | yq -y . >> $FILE
echo "### [dp3t_when]" >> $FILE
##print $(_parse given given
##		_parse when when
##		_parse then then
##		_parse simple when
##		_parse coconut when) > $tmp

# TODO: see if transformation below needed, else just print $tmp
#cat <<EOF | zenroom -a $tmp
#raw_docs = JSON.decode(DATA)
#tbl = { }
#for k,v in ipairs(raw_docs) do
#	for k,v in pairs(v) do
#  	    tbl[k] = v
#	end
#end
#print(JSON.encode(tbl))
#EOF
# rm $tmp

# print("URL64: "..OCTET.from_string(CBOR.encode(tbl)):url64())

