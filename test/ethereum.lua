

-- function bigEndianSize(num)
--    -- How many byte do I need in big endian encoding
--    local i = INT.new(0);
--    local n = BIG.new(1); -- keep increasing n untill it is bigger than num
--    while n < num and i < 4 do
--       n = n * BIG.new(256); -- shift of a byte, does LUA have the shift operator?
--       i = i + 1;
--    end

--    return i;
-- end

-- assert(bigEndianSize(INT.new(50)) == INT.new(1))
-- assert(bigEndianSize(INT.new(900)) == INT.new(2))
-- assert(bigEndianSize(BIG.new(1000000000)) == INT.new(4))

-- Are BIG and INT the same thing?

function encodeRLP(data)
   local header = nil
   local res = nil
   local byt = nil
   if type(data) == 'table' then
      -- empty octet?
      res = nil
      for _, v in pairs(data) do
	 if res then -- trick, empty octet?
	    res = res .. encodeRLP(v)
	 else
	    res = encodeRLP(v)
	 end
      end

      if #res < 56 then
	 res = O.to_octet(INT.new(192+#res)) .. res
      else
	 -- Length of the result to be saved before the bytes themselves
	 byt = O.to_hex(O.to_octet(INT.new(#res)))

	 header = O.to_octet(INT.new(247+#byt//2))

	 -- Append bytes with big endian order
	 for i=1, #byt//2, 1 do
	    header = header .. O.from_hex(string.sub(byt, 2*i-1, 2*i))
	 end

      end
   else
      -- Octet aka byte array
      res = O.to_octet(data)
      -- Empty octet?
      -- index single bytes of an octet
      byt = INT.new('0x' .. string.sub(hex(res), 1, 2))

      -- I don't link that bytes[1] is not integer
      if #res ~= 1 or byt >= INT.new(128) then
	 if #res < 56 then
	    header = O.to_octet(INT.new(128+#res))
	 else
	    -- Length of the result to be saved before the bytes themselves
	    byt = O.to_hex(O.to_octet(INT.new(#res)))

	    header = O.to_octet(INT.new(183+#byt//2))

	    for i=1, #byt//2, 1 do
	       header = header .. O.from_hex(string.sub(byt, 2*i-1, 2*i))
	    end
	 end
      end

      
   end
   if header then
      res = header .. res
   end
   return res
end

assert(encodeRLP(O.from_hex('7f')) == O.from_hex('7f'))
assert(encodeRLP(O.from_hex('ff')) == O.from_hex('81ff'))
-- ATTENTION empty sequence
--assert(encodeRLP(O.from_hex('')) == O.from_hex('80'))
assert(encodeRLP(O.from_hex('00')) == O.from_hex('00'))
assert(encodeRLP(O.from_hex('1122334455667788112233445566778811223344556677881122334455667788')) == O.from_hex('a01122334455667788112233445566778811223344556677881122334455667788'))
assert(encodeRLP(O.from_hex('11223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788')) == O.from_hex('b84011223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788'))

assert(encodeRLP({O.from_hex('11223344556677881122334455667788'), O.from_hex('1122334455667788')}) == O.from_hex('da9011223344556677881122334455667788881122334455667788'))

assert(encodeRLP({O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')}) == O.from_hex('f85794627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))
assert(encodeRLP({O.from_hex('c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'), O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')}) == O.from_hex('f878a0c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d394627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))
