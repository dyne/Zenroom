--Taken from https://datatracker.ietf.org/doc/html/rfc4648#section-6

assert(O.empty():base32() == "")
assert(O.from_string("f"):base32() == "MY======")
assert(O.from_string("fo"):base32() == "MZXQ====")
assert(O.from_string("foo"):base32() == "MZXW6===")
assert(O.from_string("foob"):base32() == "MZXW6YQ=")
assert(O.from_string("fooba"):base32() == "MZXW6YTB")
assert(O.from_string("foobar"):base32() == "MZXW6YTBOI======")
print("OK test for to_base32() function")

assert(O.from_base32("MY======"):str() == "f")
assert(O.from_base32("MZXQ===="):str() == "fo")
assert(O.from_base32("MZXW6==="):str() == "foo")
assert(O.from_base32("MZXW6YQ="):str() == "foob")
assert(O.from_base32("MZXW6YTB"):str() == "fooba")
assert(O.from_base32("MZXW6YTBOI======"):str() == "foobar")
print("OK test for from_base32() function")

a = O.zero(1000);
assert(O.from_base32(a:base32()) == a)
a = O.zero(1001);
assert(O.from_base32(a:base32()) == a)
a = O.zero(1002);
assert(O.from_base32(a:base32()) == a)

one = O.from_hex('01');
a = O.zero(1000000);
a:fill(one);
assert(O.from_base32(a:base32()) == a)
a = O.zero(1000001);
a:fill(one);
assert(O.from_base32(a:base32()) == a)
a = O.zero(1000001);
a:fill(one);
assert(O.from_base32(a:base32()) == a)
print("OK test for base32")
