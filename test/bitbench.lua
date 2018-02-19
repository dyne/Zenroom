-- Microbenchmark for bit operations library. Public domain.
-- TODO: test results

local function bench(name, t)
  local n = 10
  -- repeat
    -- local tm = os.clock()
    t(n)
  --   tm = os.clock() - tm
  --   if tm > 1 then
  --     local ns = tm*1000/(n/1000000)
  --     io.write(string.format("%-15s %6.1f ns\n", name, ns-base))
  --     return ns
  --   end
  --   n = n + n
  -- until false
end

-- The overhead for the base loop is subtracted from the other measurements.
base = bench("loop baseline", function(n)
  local x = 0; for i=1,n do x = x + i end
end)

bench("tobit", function(n)
  local f = tobit or cast
  local x = 0; for i=1,n do x = x + f(i) end
end)

bench("bnot", function(n)
  local f = bnot
  local x = 0; for i=1,n do x = x + f(i) end
end)

bench("bor/band/bxor", function(n)
  local f = bor
  local x = 0; for i=1,n do x = x + f(i, 1) end
end)

bench("shifts", function(n)
  local f = lshift
  local x = 0; for i=1,n do x = x + f(i, 1) end
end)

bench("rotates", function(n)
  local f = rol
  local x = 0; for i=1,n do x = x + f(i, 1) end
end)

bench("bswap", function(n)
  local f = bswap
  local x = 0; for i=1,n do x = x + f(i) end
end)

