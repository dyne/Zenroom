#!/usr/bin/env zsh


. ../utils.sh

zen=($*)
zen=${zen:-../../src/zenroom}
if [ ! -r ${zen} ]; then zen="../../meson/zenroom"; fi

run_zenroom_on_cortexm_qemu(){
	qemu_zenroom_run "$*"
	cat ./outlog
}

if [[ "$1" == "cortexm" ]]; then
	zen=run_zenroom_on_cortexm_qemu
fi

# echo "using: $zen"
secret="This is the secret message that is sent among people."
ppl=(zora vuk mira darko)

tmp=`mktemp -d`
# echo "tempdir: $tmp"

generate() {
	tmpfile=`mktemp`
    for p in $ppl; do
        cat <<EOF >$tmpfile && $zen $tmpfile > $tmp/$p-keys.json 2>/dev/null
k = ECDH.keygen()
print( JSON.encode(deepmap(O.to_hex, k)) )
EOF
        cat <<EOF >$tmpfile && $zen -k $tmp/$p-keys.json $tmpfile > $tmp/$p-envelop.json 2>/dev/null
keys = JSON.decode(KEYS)
envelop = JSON.encode({
    message="$secret",
    pubkey=keys['public']})
print(envelop)
EOF
    done
	rm -f $tmpfile
}

test_encrypt() {
    from=$1
    to=$2
	tmpfile=`mktemp`
    cat <<EOF >$tmpfile && $zen -k $tmp/$from-keys.json -a $tmp/$to-envelop.json $tmpfile \
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
      JSON.encode({ public = ECDH.pubgen(sender.private),
	  				iv = iv }) }
session = ECDH.session(sender.private, recipient.public)
ciphermsg.text, ciphermsg.checksum =
    AES.gcm_encrypt(session,
	 str('$secret'), iv,
	  ciphermsg.header)
print(JSON.encode(ciphermsg))
EOF
	rm -f $tmpfile
}

test_decrypt() {
    from=$1
    to=$2
	tmpfile=`mktemp`
    cat <<EOF >$tmpfile && $zen -k $tmp/$to-keys.json -a $tmp/from-$from-to-$to-cryptomsg.json $tmpfile 2>/dev/null
keys = JSON.decode(KEYS)
data = JSON.decode(DATA)
recipient = { }
recipient.private = hex(keys.private)
sender = { }
-- header is the public key of sender
decode = { header = JSON.decode(data.header) }
sender.public = O.from_base64(decode.header.public)
session = ECDH.session(recipient.private, sender.public)
decode.text, decode.checksum =
    AES.gcm_decrypt(session, O.from_base64(data.text), O.from_base64(decode.header.iv), data.header)
print(decode.text:str())
EOF
	rm -f $tmpfile
}

print - "== Running integration tests for ECDH"

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
				cat $tmp/$to-keys.json | jq
				print - "INPUT data:"
				cat $tmp/from-$from-to-$to-cryptomsg.json | jq
				# print $secret | xxd
				print - "OUTPUT string: ${#res} bytes"
				print $res
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

# just in case
[[ "$tmp" != "/" ]] && rm -rf "$tmp"
print - "== All tests passed OK"
return 0
