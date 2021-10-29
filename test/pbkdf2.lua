tests = {
   {
      p="password",
      s="salt",
      c=1,
      dklen=32,
      dk=O.from_hex('120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b')
   },
   {
      p="password",
      s="salt",
      c=4096,
      dklen=32,
      dk=O.from_hex('c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a')
   }
}

for k, v in pairs(tests) do
   assert(HASH.pbkdf2(HASH.new('sha256'), O.from_str(v.p), {
         salt=O.from_str(v.s),
         iterations=v.c,
         length=v.dklen
   }) == v.dk)
end
