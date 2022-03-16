x = F.new(42)
xoct = x:octet()
y = F.new(xoct)
assert(x == y)


z = F.new(12.5)
assert(x ~= z)
assert(not (x ~= y))
assert(not (x == z))

print(x+z)
print(x-z)
print(x*z)
print(x/z)
