#!/usr/bin/env zsh

bin=${1:-zenroom-shared}
[[ -r test ]] || {
	print "Run from base directory: ./test/$0"
	return 1
}
zen="src/$bin"
# echo "using: $zen"
enc=${2:-"b58"}
algo=${3:-"x25519"}
symc=${4:-"norx"}
secret="This is the secret message that is sent among people."
ppl=(zora vuk mira darko)

tmp=`mktemp -d`
# echo "tempdir: $tmp"

generate() {
	for p in $ppl; do
		cat <<EOF | $zen - > $tmp/$p-keys.json
json = cjson()
pk, sk = keygen_session_$algo()
keypair = json.encode({
      public=encode_$enc(pk),
      secret=encode_$enc(sk)})
print(keypair)
EOF
		cat <<EOF | $zen -k $tmp/$p-keys.json - > $tmp/$p-envelop.json
json = cjson()
keys = json.decode(KEYS)
envelop = json.encode({
    message="$secret",
    pubkey=keys.public})
print(envelop)
EOF
	done
}

encrypt() {
    from=$1
    to=$2
    cat <<EOF | $zen -k $tmp/$from-keys.json -a $tmp/$to-envelop.json - \
					 > $tmp/from-$from-to-$to-cryptomsg.json
json = cjson()
keys = json.decode(KEYS)
data = json.decode(DATA)
nonce = string.sub(encode_b64(randombytes(32)),1,32)
k = exchange_session_$algo(
  decode_$enc(keys.secret),
  decode_$enc(data.pubkey))
enc = encrypt_$symc(k,nonce,data.message)
print(json.encode({
    encmsg=encode_$enc(enc),
    pubkey=keys.public,
	nonce=nonce}))
EOF
}

decrypt() {
	from=$1
	to=$2
	cat <<EOF | $zen -k $tmp/$to-keys.json -a $tmp/from-$from-to-$to-cryptomsg.json -
json = cjson()
keys = json.decode(KEYS)
data = json.decode(DATA)
k = exchange_session_$algo(
  decode_$enc(keys.secret),
  decode_$enc(data.pubkey))
dec = decrypt_$symc(k,data.nonce,decode_$enc(data.encmsg))
print(dec)
EOF
}

print - "== Running integration tests for asymmetric crypto messaging"
generate 2>/dev/null

for p in $ppl; do
	for pp in $ppl; do
		[[ "$p" = "$pp" ]] && continue
		encrypt $p $pp 2>/dev/null
	done
done

for p in $ppl; do
	for pp in $ppl; do
		[[ "$p" = "$pp" ]] && continue
		res=`decrypt $pp $p 2>/dev/null`
		if [[ "$secret" != "$res" ]]; then
			print - "ERROR in integration luazen test: from $p to $pp"
			print - "$secret"
			print - "$res"
			print - "envelope $from:"
			cat $tmp/$from-envelop.json
			print - "recipient-keys $to:"
			cat $tmp/$to-keys.json
			print - "cryptomsg:"
			cat $tmp/from-$from-to-$to-cryptomsg.json
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
