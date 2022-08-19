-- some test for shift right

for i=0,20 do
   print()
   print(i)
   divisor = O.from_number(2^i)
   before = BIG.new(O.random(5+i*2))
   after = BIG.shr(before, i)
   print(before:octet():pad(5+i*2):bin())
   print(after:octet():pad(5+i*2):bin())
   assert(before/INT.new(divisor) == after, "shr has not worked as intended")
   assert(before>>i == after, ">> has not worked as intented")
end


huge=INT.new(O.from_hex("FBFFDFB70126F9FE83CF124CF22FFFFFF01F3B788DA11A846B8D623D1D43584763B70B79C43909EC6EDC880461EE95A6"))

for i=0,30 do
   print()
   print(i)
   divisor = O.from_number(2^i)
   before = huge
   after = BIG.shr(before, i)
   print(before:octet():pad(48):bin())
   print(after:octet():pad(48):bin())
   assert(before/INT.new(divisor) == after, "shr has not worked as intended")
   assert(before>>i == after, ">> has not worked as intented")
end

