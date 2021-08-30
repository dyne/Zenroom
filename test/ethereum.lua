
-- the empty octect is encoded as nil
-- a table contains in the first position (i.e. 1) the number of elements
function encodeRLP(data)
   local header = nil
   local res = nil
   local byt = nil
   if data == nil then
      return O.from_hex('80')
   end
   if type(data) == 'table' then
      -- empty octet
      res = O.new()
      for i=2, data[1]+1, 1 do
	    res = res .. encodeRLP(data[i])
      end
      if #res < 56 then
	 res = INT.new(192+#res):octet() .. res
      else
	 -- Length of the result to be saved before the bytes themselves
	 byt = INT.new(#res):octet()
	 header = INT.new(247+#byt):octet() .. byt

      end
   elseif iszen(type(data)) then
      -- Octet aka byte array
      res = data:octet()

      -- Empty octet?
      -- index single bytes of an octet
      local byt = INT.new( res:chop(1) )

      if #res ~= 1 or byt >= INT.new(128) then
	 if #res < 56 then
	    header = INT.new(128+#res):octet()
	 else
	    -- Length of the result to be saved before the bytes themselves
	    byt = INT.new(#res):octet()
	    header = INT.new(183+#byt):octet() .. byt
	 end
      end

   else
      error("Invalid data type for ETH RLP encoder: "..type(data))
      
   end
   if header then
      res = header .. res
   end
   return res
end

assert(encodeRLP(O.from_hex('7f')) == O.from_hex('7f'))
assert(encodeRLP(O.from_hex('ff')) == O.from_hex('81ff'))
-- ATTENTION empty sequence
assert(encodeRLP(nil) == O.from_hex('80'))
assert(encodeRLP(O.from_hex('00')) == O.from_hex('00'))
assert(encodeRLP(O.from_hex('1122334455667788112233445566778811223344556677881122334455667788')) == O.from_hex('a01122334455667788112233445566778811223344556677881122334455667788'))
assert(encodeRLP(O.from_hex('11223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788')) == O.from_hex('b84011223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788'))

assert(encodeRLP({2, O.from_hex('11223344556677881122334455667788'), O.from_hex('1122334455667788')}) == O.from_hex('da9011223344556677881122334455667788881122334455667788'))

assert(encodeRLP({3, O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')}) == O.from_hex('f85794627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))
assert(encodeRLP({4, O.from_hex('c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'), O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')}) == O.from_hex('f878a0c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d394627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))


-- the transaction I want to encode is (e.g.)

-- start Besu with the following command
-- besu --network=dev --miner-enabled --miner-coinbase=0xfe3b557e8fb62b89f4916b721be55ceb828dbd73 --rpc-http-cors-origins="all" --host-allowlist="*" --rpc-ws-enabled --rpc-http-enabled --data-path=/tmp/tmpDatdir


-- | nonce     |                                          0 |
-- | gas price |                                          0 |
-- | gas limit |                                      25000 |
-- | to        | 0x627306090abaB3A6e1400e9345bC60c78a8BEf57 |
-- | value     |                                         11 |
-- | data      |                                            |
-- | chainId   |                                       1337 |

-- 0 is encoded as the empty octet, which is treated as nil

tx = {}
tx["nonce"] = nil
tx["gasPrice"] = INT.new(1000)
tx["gasLimit"] = INT.new(25000) 
tx["to"] = O.from_hex('627306090abaB3A6e1400e9345bC60c78a8BEf57')
tx["value"] = O.from_hex('11')
tx["data"] = nil
-- v contains the chain id (when the transaction is not signed)
tx["v"] = INT.new(1337)
tx["r"] = nil
tx["s"] = nil

from = O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f')


function encodeTransaction(tx)
   local fields = {9, tx["nonce"], tx["gasPrice"], tx["gasLimit"], tx["to"],
	     tx["value"], tx["data"], tx["v"], tx["r"], tx["s"]}
   return encodeRLP(fields)
end

-- from milagro's ROM, halved (works only with SECP256K1 curve)
-- const BIG_256_28 CURVE_Order_SECP256K1= {0x364141,0xD25E8CD,0x8A03BBF,0xDCE6AF4,0xFFEBAAE,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xF};
halfSecp256k1n = INT.new(hex('7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0'))

function signEcdsaEth(sk, data) 
  local sig
  sig = nil
  repeat
    sig = ECDH.sign_hashed(sk, data, #data)
  until(INT.new(sig.s) < halfSecp256k1n);

  return sig
end

-- modify the input transaction
function encodeSignedTransaction(sk, tx)
   local H, txHash, sig, pk, x, y, two, res
   H = HASH.new('keccak256')
   txHash = H:process(encodeTransaction(tx))

   sig = signEcdsaEth(sk, txHash);

   pk = ECDH.pubgen(sk)
   x, y = ECDH.pubxy(pk);
   two = INT.new(2);
   res = tx
   res.v = two * INT.new(tx.v) + INT.new(35) + INT.new(y) % two
   res.r = sig.r
   res.s = sig.s

   return encodeTransaction(res)
end



print( encodeSignedTransaction(from, tx):hex() )
