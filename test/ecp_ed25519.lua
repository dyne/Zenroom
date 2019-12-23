print()
print '= ELLIPTIC CURVE ARITHMETIC OPERATIONS TESTS FOR ED25519'
print()

-- test values found in milagro's vector_ED25519.txt
ecp1 = ecp.new(
   octet.from_hex('77B7CB8C1B285FBD40D9BC49D3DA20489CC18272EEDDD057E7120E1DE38A3B5C'),
   octet.from_hex('67D0E5D15854E75154DEF7EB3CE0C3E8B3997347AB8061D8DE8F6BAAE02A154F'))
ecp2 = ecp.new(
   octet.from_hex('0C52B2D8BC72606D92C1337662AEEC099876C03F628D7195FAB6CD7A527DDC4F'),
   octet.from_hex('206EF634A6A61E9995149FF7A969E0A3C4D0B8CA9AC353DB3FC4C72746A5520B'))

print("ECP1 =", ecp1)
print("ECP1 octet: ", ecp1:octet():base64());
print("ECP2 =", ecp2)
print("ECP2 octet: ", ecp2:octet():base64());

print "test addition's commutativity"
assert(ecp1 + ecp2 == ecp2 + ecp1)
print "OK"

print "test addition's associativity"
ecpsum = ecp.new(
   octet.from_hex('56745BF3132BBE3B36555A1074CB26EC100265303D19FA8628D8513BC73935D2'),
   octet.from_hex('70D5370B9C54F9E291DC864D03616617CCF50B03D19544A8485A75F7B93D790F'))
ecpaux1 = ecp1 + ecp2 + ecpsum
ecpaux2 = ecpsum + ecp2 + ecp1
assert(ecpaux1 == ecpaux2)
print "OK"

print "test subtraction"
ecpsub = ecp.new(
   octet.from_hex('0AF410C7AA6814A689E4FB9C91C896428DDED45BEE36F32EEF7A6F77922325A8'),
   octet.from_hex('4C1EEA42B7EFBE461468927ADBFF55DB786D64140F3AAF39B7E60C3B759F460A'))
assert(ecp1 - ecp2 == ecpsub)
print "OK"

print "test negative"
ecpneg = ecp.new(
   octet.from_hex('08483473E4D7A042BF2643B62C25DFB7633E7D8D11222FA818EDF1E21C75C491'),
   octet.from_hex('67D0E5D15854E75154DEF7EB3CE0C3E8B3997347AB8061D8DE8F6BAAE02A154F'))
assert(ecp1:negative() == ecpneg)
print "OK"

print "test double"
ecpdbl = ecp.new(
   octet.from_hex('2B0E1601EF6533B58B75BB0117C8A1449B5D47D73ABF1BC13B2DE948BF552AD0'),
   octet.from_hex('15A5654CA8A40C561A088B8419017EA1C99C18BC749D585033BECB5633A5207A'))
assert(ecp1:double() == ecpdbl)
print "OK"

print "test multiplication"
ecpmul = ecp.new(
   octet.from_hex('227FC8E60FC4C5D4F152AF1F0B8BE8F96FE5915DCE27118251032A6053247077'),
   octet.from_hex('17183620D6FF32276C206F2F782F4C2FA147185E9FE71F5A4F710CA577F0E852'))
bigscalar = octet.from_hex('75DB735876C97D6FE2510BE8EEBE50A1655D55ED15E65667A0689271B6518F3C')
assert(ecp1 * bigscalar == ecpmul)
print "OK"

print "more misc tests on operations"
assert( ecp1:double() == ecp1 + ecp1)
assert( ecp1:double() == ecp1 * 2)
assert( ecp1 + ecp1 + ecp1 ~= ecp1 + ecp1)
assert( (ecp1:negative() + ecp1):isinf() )
print "OK"

print "test infinity"
O = ecp.infinity()
assert( ecp1 + O == ecp1)
assert( ecp1:negative() + ecp1 == O)
print "OK"
