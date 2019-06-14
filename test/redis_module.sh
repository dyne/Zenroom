#!/usr/bin/zsh

# integration tests for running redis-zenroom module

redis-server --loadmodule zenroom/src/redis_zenroom.so-x86_64.so &
sleep .5
echo "zenroom.version" | redis-cli
echo "set hello \"print('hello world!')\"" | redis-cli
echo "zenroom.exec hello" | redis-cli

# simple hashing and key derivation
echo "set hash \"print(ECDH.kdf(HASH.new(),'pappavone'):base64())\"" | redis-cli
hash=$(echo "zenroom.exec hash" | redis-cli)
print "hash: $hash"
if [[ $hash == "NFDRdiAobJb/FGa6vRKxCT3AlPefZ1WWg+iLtxqHlkw=" ]]; then
	print "OK hash"
else
	print "ERROR hash"
fi	

echo "shutdown nosave" | redis-cli
