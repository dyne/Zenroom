#!/usr/bin/env sh
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
    echo "$(grep -i ''"${action}"'(' $R/zencode_${section}.lua \
	| cut -d '"' -f2 \
    | jq -Rj '. | { '"${action}"': .}' \
    | jq -s . \
    | jq -j '.| {'"${section}"': .}')"
}

FILE=$1

echo "### [given]" > $FILE
echo $(_parse given given) | yq -y . >> $FILE
echo "### [given]" >> $FILE

echo "### [when]" >> $FILE
echo $(_parse when when) | yq -y . >> $FILE
echo "### [when]" >> $FILE

echo "### [then]" >> $FILE
echo $(_parse then then) | yq -y . >> $FILE
echo "### [then]" >> $FILE

echo "### [array]" >> $FILE
echo $(_parse array when) | yq -y . >> $FILE
echo "### [array]" >> $FILE

echo "### [random]" >> $FILE
echo $(_parse random when) | yq -y . >> $FILE
echo "### [random]" >> $FILE

echo "### [hash]" >> $FILE
echo $(_parse hash when) | yq -y . >> $FILE
echo "### [hash]" >> $FILE

echo "### [ecdh]" >> $FILE
echo $(_parse ecdh when) | yq -y . >> $FILE
echo "### [ecdh]" >> $FILE

echo "### [credential]" >> $FILE
echo $(_parse credential when) | yq -y . >> $FILE
echo "### [credential]" >> $FILE

echo "### [petition]" >> $FILE
echo $(_parse petition when) | yq -y . >> $FILE
echo "### [petition]" >> $FILE

echo "### [dp3t]" >> $FILE
echo $(_parse dp3t when) | yq -y . >> $FILE
echo "### [dp3t]" >> $FILE

echo "### [secshare]" >> $FILE
echo $(_parse secshare when) | yq -y . >> $FILE
echo "### [secshare]" >> $FILE

echo "### [validators]" >> $FILE
echo $(_parse validators when) | yq -y . >> $FILE
echo "### [validators]" >> $FILE

##echo $(_parse given given
##		_parse when when
##		_parse then then
##		_parse simple when
##		_parse coconut when) > $tmp

# TODO: see if transformation below needed, else just echo $tmp
#cat <<EOF | zenroom -a $tmp
#raw_docs = JSON.decode(DATA)
#tbl = { }
#for k,v in ipairs(raw_docs) do
#	for k,v in pairs(v) do
#  	    tbl[k] = v
#	end
#end
#echo(JSON.encode(tbl))
#EOF
# rm $tmp

# echo("URL64: "..OCTET.from_string(CBOR.encode(tbl)):url64())
