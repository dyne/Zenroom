#!/usr/bin/env zsh

[[ -r test ]] || {
	print "Run from base directory: ./test/$0"
	return 1
}
zen=${1:-./src/$bin}
# echo "using: $zen"
enc=${2:-"base64"}
secret="This is the secret message that is sent among people."
ppl=(zora vuk mira darko)

tmp=`mktemp -d`
# echo "tempdir: $tmp"

generate() {
	for p in $ppl; do
		cat <<EOF | $zen 2>/dev/null > $tmp/$p-keys.json
keyring = ecdh.new()
keyring:keygen()
keypair = json.encode({
      public=keyring:public():$enc(),
      secret=keyring:private():$enc()})
print(keypair)
EOF
		cat <<EOF | $zen 2>/dev/null -k $tmp/$p-keys.json > $tmp/$p-envelop.json
keys = json.decode(KEYS)
envelop = json.encode({
    message="$secret",
    pubkey=keys['public']})
print(envelop)
EOF
	done
}

encrypt() {
    from=$1
    to=$2
    cat <<EOF | $zen -k $tmp/$from-keys.json -a $tmp/$to-envelop.json \
					 > $tmp/from-$from-to-$to-cryptomsg.json 2>/dev/null
keys = json.decode(KEYS)
data = json.decode(DATA)
recipient = ecdh.new()
recipient:public(octet.from_$enc(data['pubkey']))
sender = ecdh.new()
sender:private(octet.from_$enc(keys['secret']))
k = sender:session(recipient)
enc = sender:encrypt(k,octet.from_string(data['message']))
print(json.encode({
    encmsg=enc:base64(),
    pubkey=keys['public']}))
EOF
}

decrypt() {
	from=$1
	to=$2
	cat <<EOF | $zen -k $tmp/$to-keys.json -a $tmp/from-$from-to-$to-cryptomsg.json 2>/dev/null
keys = json.decode(KEYS)
data = json.decode(DATA)
recipient = ecdh.new()
recipient:private(octet.from_$enc(keys['secret']))
sender = ecdh.new()
sender:public(octet.from_$enc(data['pubkey']))
k = recipient:session(sender)
dec = recipient:decrypt(k,octet.from_$enc(data['encmsg']))
print(dec)
EOF
}

print - "== Running integration tests for asymmetric crypto messaging"
generate

for p in $ppl; do
	for pp in $ppl; do
		[[ "$p" = "$pp" ]] && continue
		encrypt $p $pp
	done
done

for p in $ppl; do
	for pp in $ppl; do
		[[ "$p" = "$pp" ]] && continue
		res=`decrypt $pp $p 2>/dev/null`
		if [[ "$secret" != "$res" ]]; then
			print - "ERROR in integration luazen test: $tmp"
			print - "$secret (${#secret} bytes)"
			print $secret | xxd
			print - "$res (${#res} bytes)"
			print $res | xxd
			print - "envelope from ${pp}:"
			cat $tmp/$pp-envelop.json
			print - "recipient-keys to ${p}:"
			cat $tmp/$p-keys.json
			print - "cryptomsg:"
			cat $tmp/from-$pp-to-$p-cryptomsg.json
			print - "==="
			return 1
		else
			# print "OK integration luazend test PASSED: from $p to $pp"
		fi
	done
done

# just in case
[[ "$tmp" != "/" ]] && rm -rf "$tmp"
print - "== All tests passed OK"
return 0
