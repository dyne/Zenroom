--
-- Generates the private of the authorities
--

rng = RNG.new()
order = ECP.order() -- get the curves order in a big
private = rng:big() % order


export = JSON.encode(
   {
      private  = tostring(private)
   }
)
print(export)
