-- blake2b tested without key and salt (TODO: api similar to HMAC)
vectors = JSON.decode(DATA)
blake = HASH.new('blake2')
c=0
for _,i in ipairs(vectors.array) do
   if i.input ~= "" and i.key == "" and i.salt == "" then
	  write('.')
	  assert( blake:process(O.from_hex(i.input)) == O.from_hex(i.out))
	  c=c+1
   end
end
print("OK")
print(c.." test vectors passed for blake2b")
