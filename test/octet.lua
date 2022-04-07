print '= OCTET FIRST CLASS CITIZEN TESTS'
print()

-- octet = require'octet'

function dotest(l,r,reason)
   if(l == r
	  and
	  #l == #r) then
	  return true
   else
	  print 'ERROR'
	  print 'left:'
	  print(l)
	  print 'right:'
	  print(r)
	  assert(false, reason)
   end
end

-- random and  check hash of octets
-- ecdh = require'ecdh'
hash = HASH.new()
right = OCTET.string([[Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.]])
teststr = right:string()
test64  = right:base64()
testU64 = right:url64()
test58  = right:base58()
test45  = right:base45()
testhex = right:hex()
testbin = right:bin()

print '== test octet copy'
left = right;
dotest(left, right)
dotest(hash:process(left),hash:process(right))

print '== test string import/export'
left = OCTET.string(teststr)
print '=== compare octets'
dotest(left, right)
print '=== compare strings'
dotest(left:string(), teststr)
print '=== compare hashes'
dotest(hash:process(left), hash:process(right))

print '== test base64 import/export'
left = OCTET.base64(test64)
dotest(left, right)
dotest(left:base64(), test64)
dotest(hash:process(left), hash:process(right))

print '== test url64 import/export'
left = OCTET.url64(testU64)
dotest(left, right)
dotest(left:url64(), testU64)
dotest(hash:process(left), hash:process(right))

print '== test base58 import/export'
left = OCTET.base58(test58)
dotest(left, right)
dotest(left:base58(), test58)
dotest(hash:process(left), hash:process(right))

print '== test base45 import/export'
left = OCTET.from_base45(test45)
dotest(left, right)
dotest(left:base45(), test45)
dotest(hash:process(left), hash:process(right))



print '== test hex import/export'
left = OCTET.hex(testhex)
dotest(left, right)
dotest(left:hex(), testhex)
dotest(hash:process(left), hash:process(right))

print '== test bin import/export'
left = OCTET.bin(testbin)
dotest(left, right)
dotest(left:bin(), testbin)
dotest(hash:process(left), hash:process(right))

-- print '= OK'

print '== ECP import/export'

left = INT.random() * ECP.generator() -- ECP point aka pub key
b64 = left:octet():base64()
right = base64(b64)
dotest(left:octet(),right)
CONF.input = { }
CONF.output = { }

print '== JSON import/export'
function jsontest(reason)
   CONF.input.encoding = input_encoding(reason)
   CONF.output.encoding = { fun = guess_outcast(reason),
			    name = reason }
   local str = JSON.encode({public = left})
   right = JSON.decode(str)
   right.public = CONF.input.encoding.fun(right.public)
   dotest(left:octet(),right.public)
   ECP.new(right.public) -- test if ecp point on curve
end
jsontest("hex")
jsontest("base58")
jsontest("url64")
jsontest("base64")
jsontest("bin")

print '== JSON cryptotests'
-- more testing using crypto verification of pub/priv keypair
function jsoncryptotest(f)
   local key = {}
   key.private = INT.random()
   key.public = key.private * ECP.generator()
   local str = JSON.encode({private = _G[f](key.private)})
   dstr = JSON.decode(str).private
   doct = _G[f](dstr)
   assert(doct == key.private, "Error importing to OCTET from "..f..":\n"
			 .._G[f](doct).."\n".._G[f](key.private))
   dint = BIG.new(_G[f](dstr))
   assert(dint * ECP.G() == key.public, "Error importing to BIG from "..f..":\n"
			 .._G[f](dint).."\n".._G[f](key.private))
end
jsoncryptotest('hex')
jsoncryptotest('base58')
-- jsoncryptotest('base45')
jsoncryptotest('base64')
jsoncryptotest('url64')
jsoncryptotest('bin')

print '= OK'
