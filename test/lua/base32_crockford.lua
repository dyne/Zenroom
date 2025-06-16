--Taken from https://www.npmjs.com/package/crockford-base32crockford

oct=O.from_string("some string")
assert(oct:base32crockford() == "EDQPTS90EDT74TBECW")
assert(O.from_base32_crockford("EDQPTS90EDT74TBECW"):str() == "some string")
assert(O.from_base32_crockford("EDQPTS-90EDT7-4TBECW"):str() == "some string")
assert(O.from_base32_crockford("1P10E"):hex() == "0d8207")
assert(O.from_base32_crockford("IPL0E"):hex() == "0d8207")
assert(O.from_base32_crockford("iploe"):hex() == "0d8207")

print("OK!")

--The next tests are made from https://www.dcode.fr/crockford-base-32-encoding
oct1= O.from_string("encode this string")
assert(oct1:base32crockford() == "CNQ66VV4CMG78T39ECG76X3JD5Q6E")
assert(oct1:base32crockford(true) == "CNQ66VV4CMG78T39ECG76X3JD5Q6EZ")
assert(O.from_base32_crockford(oct1:base32crockford()):str() == "encode this string")
assert(O.from_base32_crockford(oct1:base32crockford(true), true):str() == "encode this string")
--example with a special character as checksum
oct2= O.from_string("encode this string4")
assert(oct2:base32crockford(true) == "CNQ66VV4CMG78T39ECG76X3JD5Q6ED0~")
assert(O.from_base32_crockford("CNQ66VV4CMG78T39ECG76X3JD5Q6ED0~", true):str() == "encode this string4")
--example with "-" in the middle
oct3=O.from_string("another string")
assert(oct3:base32crockford(true,4) == "C5Q6-YX38CNS20WVME9MPWSRB")
assert(oct3:base32crockford(false,4) == "C5Q6-YX38CNS20WVME9MPWSR")
assert(O.from_base32_crockford("C5Q6-YX38CNS20WVME9MPWSRB",true) == O.from_base32_crockford("C5Q6-YX38CNS20WVME9MPWSR",false))

print("OK!")

a = O.zero(1000);
assert(O.from_base32_crockford(a:base32crockford()) == a)
a = O.zero(1001);
assert(O.from_base32_crockford(a:base32crockford(true),true) == a)
a = O.zero(1002);
assert(O.from_base32_crockford(a:base32crockford(true, 7), true) == a)

one = O.from_hex('01');
a = O.zero(1000000);
a:fill(one);
assert(O.from_base32_crockford(a:base32crockford()) == a)
a = O.zero(1000001);
a:fill(one);
assert(O.from_base32_crockford(a:base32crockford(true),true) == a)
a = O.zero(1000001);
a:fill(one);
assert(O.from_base32_crockford(a:base32crockford(false,4),false) == a)
print("OK test for base32crockford")
