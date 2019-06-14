#!/usr/bin/zsh

# integration tests for running redis-zenroom module

redis-server --loadmodule zenroom/src/redis_zenroom.so-x86_64.so &

# sha256 -> base64 hashed value of 'hello world!'
hh="9vlV1yVnkRl1jxQODNgOJ4XIW06Ji4+dB6u3Nlgl2fk="

sleep .5
echo "zenroom.version" | redis-cli
echo "set hello \"print('hello world!')\"" | redis-cli
echo "zenroom.exec hello" | redis-cli

# OK, use simple string in hello now
echo "set hello \"hello world!\"" | redis-cli

echo "simple hashing and key derivation"
echo "set hash \"print(ECDH.kdf(HASH.new('sha256'),'hello world!'):base64())\"" | redis-cli
hash=$(echo "zenroom.exec hash" | redis-cli)
echo "hash: $hash"
if [[ $hash == $hh ]]; then
	echo "OK hash"
else
	echo "ERROR hash"
fi

echo "simple hashing of key/value contents as DATA"
echo "set hash \"print(ECDH.kdf(HASH.new('sha256'),DATA):base64())\"" | redis-cli
hash=$(echo "zenroom.exec hash hello" | redis-cli)
echo "hash: $hash"
if [[ $hash == $hh ]]; then
	echo "OK hash"
else
	echo "ERROR hash"
fi

echo "simple hashing of key/value contents as KEYS"
echo "set hash \"print(ECDH.kdf(HASH.new('sha256'),KEYS):base64())\"" | redis-cli
hash=$(echo "zenroom.exec hash hello hello" | redis-cli)
echo "hash: $hash"
if [[ $hash == $hh ]]; then
	echo "OK hash"
else
	echo "ERROR hash"
fi


echo "shutdown nosave" | redis-cli
