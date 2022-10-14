
assert(O.empty():base45() == "")
assert(O.from_string("AB"):base45() == "BB8")
assert(O.from_string("Hello!!"):base45() == "%69 VD92EX0")
assert(O.from_string("base-45"):base45() == "UJCLQE7W581")

assert(O.from_base45("BB8"):str() == "AB")
assert(O.from_base45("%69 VD92EX0"):str() == "Hello!!")
assert(O.from_base45("UJCLQE7W581"):str() == "base-45")

a = O.zero(1000);
assert(O.from_base45(a:base45()) == a)
a = O.zero(1001);
assert(O.from_base45(a:base45()) == a)
a = O.zero(1002);
assert(O.from_base45(a:base45()) == a)

one = O.from_hex('01');
a = O.zero(1000000);
a:fill(one);
assert(O.from_base45(a:base45()) == a)
a = O.zero(1000001);
a:fill(one);
assert(O.from_base45(a:base45()) == a)
a = O.zero(1000001);
a:fill(one);
assert(O.from_base45(a:base45()) == a)
