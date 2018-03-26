
ecdh = require'ecdh'
ed25519 = ecdh.new()
pk,sk = ed25519:keygen()
print 'public:'
print(pk:hex())
print 'secret:'
print(sk:hex())


ses = ed25519:session(pk,sk)
print 'session:'
print(ses:hex())
