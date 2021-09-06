-- Warning: problem importing big int

-- I get from the outside the list of unspent transactions
-- I filter the one that have enough BTC
-- e.g. from
-- [
--   {
--     "txid": "5cd1a9c46c2d06d2ae25b2eb5e819eca1850b748336deef580d49e46f852add1",
--     "vout": 1,
--     "address": "mrxDNeNhmXxpNgdcuLqAaHkcn5gPrZHPRh",
--     "label": "",
--     "scriptPubKey": "76a9147d705ebfc54c783c527d66abe48cd532a97fb28c88ac",
--     "amount": 0.00010000,
--     "confirmations": 212,
--     "spendable": true,
--     "solvable": true,
--     "desc": "pkh([7d705ebf]03fe7380f1549462e6f9fff99c2bd0084a2ce568f79f0001f020b4135385394276)#av5c7yvg",
--     "safe": true
--   },
--   {
--     "txid": "b0675436dd79bc101780c4891d2ef342a128c49e7a269ac135a14552b321ecd2",
--     "vout": 1,
--     "address": "mrxDNeNhmXxpNgdcuLqAaHkcn5gPrZHPRh",
--     "label": "",
--     "scriptPubKey": "76a9147d705ebfc54c783c527d66abe48cd532a97fb28c88ac",
--     "amount": 0.00060000,
--     "confirmations": 212,
--     "spendable": true,
--     "solvable": true,
--     "desc": "pkh([7d705ebf]03fe7380f1549462e6f9fff99c2bd0084a2ce568f79f0001f020b4135385394276)#av5c7yvg",
--     "safe": true
--   },
--   {
--     "txid": "b0b4eff88aaedc55b1ff85224cd9e93dad88f867ed093b868060024020e81ad3",
--     "vout": 1,
--     "address": "mrxDNeNhmXxpNgdcuLqAaHkcn5gPrZHPRh",
--     "label": "",
--     "scriptPubKey": "76a9147d705ebfc54c783c527d66abe48cd532a97fb28c88ac",
--     "amount": 0.00083000,
--     "confirmations": 5,
--     "spendable": true,
--     "solvable": true,
--     "desc": "pkh([7d705ebf]03fe7380f1549462e6f9fff99c2bd0084a2ce568f79f0001f020b4135385394276)#av5c7yvg",
--     "safe": true
--   }
-- ]

-- sk: af3ec27d2b92fed349a4f8baabadfa27deed8a29eb795734373e6f3e14ae5c61
-- pk: 02845b2dc1d8cf62e441e98b27ac11bec7dbc799d03f1fd2fad9642e32ce6a96ca

function opposite(num)
   res = O.new()
   for i=#num,1,-1 do
      res = res .. num:sub(i,i)
   end
   return res
end

Bech32Chars = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
BechInverse = {}
for i=1,#Bech32Chars,1 do
   BechInverse[Bech32Chars:sub(i,i)] = i-1
end

sk = O.from_hex('ffa4bb9baf74e69d2d7b10a92a7d8086e617e53d0cdb59f8099c44fad4abc03501')
pk = ECDH.pubgen(sk)

tx = {
   txIn = {
      {
	 txid= O.from_hex("71819aa4673279daa541336f829209c78a68428104c49c5bfc3f97bcaf7fa7fe"),
	 vout= 0,
      }
   },
   txOut = {
      {
	 amount = O.from_hex('012a05caf0'), -- this maybe should be a number
	 address = 'bcrt1qnyu4k62dcj0d90f20zrxn07e2pg7rgyf5esn80'
      }
   }
}

function readBech32Address(addr)
   local prefix, data, res, byt, countBit,val
   prefix = nil
   if addr:sub(1,4) == 'bcrt' then
      prefix = 4
   elseif addr:sub(1,2) == 'bc' or addr:sub(1,2) == 'tc' then
      prefix = 2
   end
   if not prefix then
      error("Not bech32")
   end
   -- +3 = do not condider separator and version bit
   data = addr:sub(prefix+3, #addr)

   res = O.new()
   byt=0 -- byte accumulator
   countBit = 0 -- how many bits I have put in the accumulator
   for i=1,#data,1 do
      val = BechInverse[data:sub(i,i)]

      -- Add 5 bits to the buffer
      byt = (byt << 5) + val
      countBit = countBit + 5

      if countBit >= 8 then
	 res = res .. INT.new(byt >> (countBit-8)):octet()
	 if countBit == 8 then
	    byt = 0
	 else
	    byt = byt % (1 << (countBit-8))
	 end
	 countBit = countBit - 8
      end
   end

   -- TODO: I dont look at the checksum
   
   return res:chop(20)
end

--print(readBech32Address('bcrt1qnyu4k62dcj0d90f20zrxn07e2pg7rgyf5esn80'):hex())

function encodeCompactSize(n)
   local res, padding, prefix, le -- littleEndian;

   if type(n) ~= "bignum" then
      n = INT.new(n)
   end
   
   padding = 0
   res = O.new()
   if n <= INT.new(252) then
      res = n:octet()
   else
      le = opposite(n:octet())
      prefix = O.new()
      if n <= INT.new('0xffff') then
	 prefix = O.from_hex('fd') 
	 padding = 2
      elseif n <= INT.new('0xffffffff') then
	 prefix = O.from_hex('fe')
	 padding = 4
      elseif n <= INT.new('0xffffffffffffffff') then
	 prefix = O.from_hex('ff')
	 padding = 8
      else
	 padding = #le
      end
      res = prefix .. le
      padding = padding - #le
   end

   if padding > 0 then
      res = res .. O.zero(padding)
   end

   return res
end

function toUInt(num, nbytes)
   if type(num) ~= "bignum" then
      num = INT.new(num)
   end
   num = opposite(num:octet())
   if #num < nbytes then
      num = num .. O.zero(nbytes - #num)
   end
   return num
end

assert(encodeCompactSize(INT.new(1)) == O.from_hex('01'))
assert(encodeCompactSize(INT.new(253)) == O.from_hex('fdfd00'))
assert(encodeCompactSize(INT.new(515)) == O.from_hex('fd0302'))

-- with not coinbase input
function buildRawTransaction(txIn)
   local raw, script
   raw = O.new()

   if tx["withness"] and #tx["withness"]>0 then
      sigwit = true
   else
      sigwit = false
   end

   -- version
   raw = raw .. O.from_hex('01000000')


   if sigwit then
      -- marker + flags
      raw = raw .. O.from_hex('0001')
   end
   
   raw = raw .. encodeCompactSize(INT.new(#tx.txIn))

   -- txIn
   for _, v in pairs(tx.txIn) do
      -- outpoint (hash and index of the transaction)
      raw = raw .. opposite(v.txid) .. toUInt(v.vout, 4)

      -- the script depends on the signature
      script = O.new()

      raw = raw .. encodeCompactSize(#script) .. script
      
      -- Sequence number disabled
      raw = raw .. O.from_hex('ffffffff')
   end

   raw = raw .. encodeCompactSize(INT.new(#tx.txOut))

   -- txOut
   for _, v in pairs(tx.txOut) do
      --raw = raw .. toUInt(v.amount, 8)
      raw = raw .. opposite(v.amount)
      if #v.amount < 8 then
	 raw = raw .. O.zero(8 - #v.amount)
      end
      
      -- fixed script to send bitcoins
      -- OP_DUP OP_HASH160 20byte
      --script = O.from_hex('76a914')

      --script = script .. v.address

      -- OP_EQUALVERIFY OP_CHECKSIG
      --script = script .. O.from_hex('88ac')
      
      -- Bech32
      script = O.from_hex('0014')
      script = script .. readBech32Address(v.address)
      
      raw = raw .. encodeCompactSize(#script) .. script
   end

   if sigwit then
      raw = raw .. encodeCompactSize(#tx["withness"])
      for _, v in pairs(tx["withness"]) do
	 raw = raw .. v
      end
   end

   raw = raw .. O.from_hex('00000000')
   
   return raw
end
--txEnc = buildRawTransaction(txIn)
--print("Prima")
--print(txEnc)
txEnc = buildRawTransaction(tx)
--print("Dopo")
--print(txEnc)
sig = ECDH.sign(pk, txEnc)

function encodeWithPrepend(bytes)
   if tonumber(bytes:sub(1,1):hex(), 16) >= 0x80 then
      bytes = O.from_hex('00') .. bytes
   end

   return bytes
end

function encodeDERSignature(sig)
   local res, tmp;

   res = O.new()

   -- r
   tmp = encodeWithPrepend(sig.r)
   res = res .. O.from_hex('02') .. INT.new(#tmp):octet() .. tmp

   -- s
   tmp = encodeWithPrepend(sig.s)
   res = res .. O.from_hex('02') .. INT.new(#tmp):octet() .. tmp
   
   res = O.from_hex('30') .. INT.new(#res):octet() .. res
   return res
end

-- print(encodeDERSignature(sig):hex())

tx["withness"] = {
   encodeDERSignature(sig)
}
print("Signed")
print(buildRawTransaction(tx):hex())
