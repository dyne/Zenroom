#!/usr/bin/env zsh

[[ -r test ]] || {
    print "Run from base directory: ./test/$0"
    return 1
}
zen=($*)
zen=${zen:-./src/zenroom}
# echo "using: $zen"
curves=(goldilocks)
secret="This is the secret message that is sent among people."
ppl=(zora vuk mira darko)

tmp=`mktemp -d`
# echo "tempdir: $tmp"

generate() {
    for p in $ppl; do
        cat <<EOF | $zen > $tmp/$p-keys.json 2>/dev/null
print( JSON.encode(map(ECDH.keygen(), hex)) )
EOF
        cat <<EOF | $zen -k $tmp/$p-keys.json > $tmp/$p-envelop.json 2>/dev/null
keys = JSON.decode(KEYS)
envelop = JSON.encode({
    message="$secret",
    pubkey=keys['public']})
print(envelop)
EOF
    done
}

test_encrypt() {
    from=$1
    to=$2
    cat <<EOF | $zen -k $tmp/$from-keys.json -a $tmp/$to-envelop.json \
                     > $tmp/from-$from-to-$to-cryptomsg.json 2>/dev/null
keys = JSON.decode(KEYS)
data = JSON.decode(DATA)
recipient = { }
recipient.public = hex(data.pubkey)
sender = { }
sender.private = hex(keys.private)
iv = O.random(16)
ciphermsg =
  { header =
      url64(JSON.encode({ public = ECDH.pubgen(sender.private),
	  	    		     iv = iv })) }
session = ECDH.session(sender.private, recipient.public)
ciphermsg.text, ciphermsg.checksum =
    ECDH.aead_encrypt(session,
	 str('$secret'), iv,
	  ciphermsg.header)
print(JSON.encode(ciphermsg))
EOF
}

test_decrypt() {
    from=$1
    to=$2
    cat <<EOF | $zen -k $tmp/$to-keys.json -a $tmp/from-$from-to-$to-cryptomsg.json 2>/dev/null
keys = JSON.decode(KEYS)
data = JSON.decode(DATA)
recipient = { }
recipient.private = hex(keys.private)
sender = { }
-- header is the public key of sender
decode = { header = JSON.decode(url64(data.header)) }
sender.public = decode.header.public
session = ECDH.session(recipient.private, sender.public)
decode.text, decode.checksum =
    ECDH.aead_decrypt(session, url64(data.text), decode.header.iv, data.header)
print(decode.text:str())
EOF
}

print - "== Running integration tests for ECDH"

for curve in $curves; do
    print "== curve: $curve"
	generate

	for p in $ppl; do
		for pp in $ppl; do
			[[ "$p" = "$pp" ]] && continue
			from=$p
			to=$pp
			# print "ENCRYPT $from -> $to"
			test_encrypt $p $pp
			# cat $tmp/from-$from-to-$to-cryptomsg.json
		done
	done

	for p in $ppl; do
		for pp in $ppl; do
			[[ "$p" = "$pp" ]] && continue
			from=$pp
			to=$p
			# print "DECRYPT $from -> $to"
			res=`test_decrypt $from $to`
			# print $res
			if [[ "$secret" != "$res" ]]; then
				print - "ERROR in integration ecdh test: $tmp"
				print "DECRYPT $from -> $to"
				print - "INPUT keys:"
				cat $tmp/$to-keys.json | json_pp
				print - "INPUT data:"
				cat $tmp/from-$from-to-$to-cryptomsg.json | json_pp
				# print $secret | xxd
				print - "OUTPUT string: ${#res} bytes"
				print $res | xxd
				print - "envelope from ${from}:"
				cat $tmp/$pp-envelop.json
				print - "recipient-keys to ${to}:"
				cat $tmp/$p-keys.json
				print - "cryptomsg:"
				cat $tmp/from-$from-to-$to-cryptomsg.json
				print - "==="
				return 1
			else
				# print "OK integration luazend test PASSED: from $p to $pp"
			fi
		done
	done
done
# just in case
[[ "$tmp" != "/" ]] && rm -rf "$tmp"
print - "== All tests passed OK"
return 0
