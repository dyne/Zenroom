print "HASH test known vectors"
H = HASH.new('sha256')
sha256_str = str('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')
sha256_hex = hex('248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1')
assert(H:process(sha256_str) == sha256_hex)
print "HASH tests OK"
