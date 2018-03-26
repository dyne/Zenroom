
secret = octet.new()
secret:string([[
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?

At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.
]])

rsa = require'rsa'
r2k = rsa.new(2048)
print '= test key generation'
r2k:keygen()

print("public key:")
print(r2k:public():base64())

print("private key:")
print(r2k:private():base64())

print '= test keys import / export'
rdup = rsa.new(2048)
rdup:public(r2k:public())
rdup:private(r2k:private())
print 'public...'
assert(rdup:public() == r2k:public())
print 'OK'

print 'private...'
assert(rdup:private() == r2k:private())
print 'OK'


print '= test oaep padding'
print("secret message size " .. #secret .. " bytes")
oaep_message = r2k:oaep_encode(secret)
print("oaep_message size: " .. #oaep_message .. " bytes")
oaep_test = r2k:oaep_decode(oaep_message);
assert(oaep_test == secret)
print 'OK'

print '= test encryption'
print("maximum size: " .. oaep_message:max() .. " bytes")
e_message = r2k:encrypt(oaep_message)
print 'OK'

print("cyphertext:")
print(e_message:base64())

print 'decryption....'
oaep_decrypt = r2k:decrypt(e_message)
assert(oaep_decrypt == oaep_message)
print 'OK'

print 'unpadding...'
message = r2k:oaep_decode(oaep_decrypt)
assert(message == secret)
print 'OK'

