print()
print '= BIG NUMBERS ARITHMETIC OPERATIONS TESTS FOR BLS383'
print()

function equals(l,r,desc)
   assert(l == r, desc .. " (__eq comparison)")
   local tr, tl
   if type(r) == "zenroom.octet" then tr = r else tr = r:octet() end
   if type(l) == "zenroom.octet" then tl = l else tl = l:octet() end
   assert(tl == tr, desc .. " (octet comparison)")
   assert(tl:string() == tr:string(), desc .. " (string comparison)")
   assert(OCTET.hamming(tl,tr)==0, desc .. " (hamming comparison)")
   return
end


print '=== compare different sizes same content'
randright = sha256(O.random(48))
left = INT.new(randright)
equals(randright,left, "INT.new octet")

print "=== BIG arithmetics from Milagro's testVectors"
-- # BIG ARITHMETICS
-- # BIGdiv = BIGmul/BIGsum.  BIGdivmod = (BIG1/0ED5066C6815047425DF 2(mod E186EB30EF))
big1 = BIG.new(hex '2758F22ABFE4085C27F2691BEBB75D7EF7BF4F9D441AD5CFC2AC3956748C1407')
big2 = BIG.new(hex '09A52FE465983AEA1FBE357D9238C11CBD0F1557248E24B9247DA6AF3D51FF8D')

BIGsum = BIG.new(hex '30FE220F257C434647B09E997DF01E9BB4CE64F468A8FA88E729E005B1DE1394')
equals(big1+big2, BIGsum, "bigsum")

bigsub = BIG.new(hex '1DB3C2465A4BCD720834339E597E9C623AB03A461F8CB1169E2E92A7373A147A')
equals(big1-big2, bigsub, "bigsub")


big1mod2 = BIG.new(hex 'C4329929831CB3A8F99325A2D4590C0382FA40B1E242EB30B59E997F4415D3')
equals(big1%big2, big1mod2, "big1mod2")

big2mod1 = BIG.new(hex '09A52FE465983AEA1FBE357D9238C11CBD0F1557248E24B9247DA6AF3D51FF8D')
equals(big2%big1, big2mod1, "big2mod1")

BIG1sqrmod2 = BIG.new(hex '08A7778730B044D458C7C0B6694090F28967DF88A91DE735A776E791956B1466')
equals(big1:modsqr(big2), BIG1sqrmod2, "sqrmod")

BIG1modneg2 = BIG.new(hex '08E0FD4B3C151E3676C4A257EF646810B98C1B1672ABE1CDF3C80815BE0DE9BA')
equals(big1:modneg(big2), BIG1modneg2, "modneg")

BIG1sqr = BIG.new(hex '060C38B068F0414079FE5C0A974FF7ABC235E057EB69CBD7536065324957288716E31984C1C8A88A14A6994FF32F20895E110C337EF09100697FD18041391831')
equals(big1:sqr(), BIG1sqr,"big1sqr")

BIG2sqr = BIG.new(hex '5D07F4D48553736D24ACA6EB3A92AF16BC076CD1279E9174D2E546C009716BCFF733C540E3590E6E0C6BC637B339649385B1C055B7AF3873E86CD2E85433A9')
equals(big2:sqr(), BIG2sqr,"big2sqr")

BIGmul = BIG.new(hex '017B84340597B6FB2F909526D24A91684871948A0A24D06C6D313D6C46D2C63E974F422047CB3844FF059E80B87997DC8EFEEB125252AA71C8422E96BA5100DB')
equals(big1*big2, BIGmul, "bigmul")
print "OK"

-- TODO: sort out the internal representation of DBIG and BIG
-- BIGdiv = BIG.new(hex '07BF132653B07B8718FFBA9CFE8F4204BC042A04BD61F58158CF0E8EE48593A3')
-- assert(BIGmul / BIGsum == BIGdiv, "div")

BIGdivmod = BIG.new(hex '8D5A4917A1')
mod = BIG.new(hex 'E186EB30EF')
div = BIG.new(hex '0ED5066C6815047425DF')
equals(big1:moddiv(div,mod), BIGdivmod, "moddiv")

-- BIGpxmul = 4D9E75B65488D47DCACD315813FCB76F76B8640D3B58EFC6D705BD1B8BE85381CF

