print '= SFPOOL REGRESSION'

for i = 1, 256 do
   local small = OCTET.zero(64)
   local large = OCTET.zero(1024)

   assert(#small == 64, 'small octet size mismatch at iteration ' .. i)
   assert(#large == 1024, 'large octet size mismatch at iteration ' .. i)

   small = nil
   large = nil
   collectgarbage('collect')
end

print 'sfpool regression ok'
