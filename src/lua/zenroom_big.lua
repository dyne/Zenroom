local big = require'big'
-- optimization: we could implement it in C
function big.sqrt(num)
  local two = BIG.new(2)
  local xn = num
  local xnn;

  if xn ~= BIG.new(0) then
    xnn = (xn + (num / xn)) / two
    while xnn < xn do
      xn = xnn
      xnn = (xn + (num / xn)) / two
    end
  end


  return xn
  
end

return big
