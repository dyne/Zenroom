-- BIP-340 test vectors embedded (selected from bip340_test_vectors.csv)
-- Full CSV parsing is done via BATS test runner; this is a smoke check.

local schnorr = require('crypto_schnorr_signature')

-- Helper: hex to OCTET
local function H(s) return OCTET.from_hex(s) end

-- Vector 1 (index 1): known valid signature
local sk1  = H("B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF")
local pk1  = H("DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659")
local aux1 = H("0000000000000000000000000000000000000000000000000000000000000001")
local msg1 = H("243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89")
local sig1 = H("6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE33418906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A")

-- Vector 0 (index 0): secret key 3, zero message, zero aux
local sk0  = H("0000000000000000000000000000000000000000000000000000000000000003")
local pk0  = H("F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9")
local aux0 = H("0000000000000000000000000000000000000000000000000000000000000000")
local msg0 = H("0000000000000000000000000000000000000000000000000000000000000000")
local sig0 = H("E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0")

local passed, failed = 0, 0

-- Test pubgen matches known public key
local function check_pubgen(name, sk, expected_pk)
   local pk = schnorr.pubgen(sk)
   if pk:hex() == expected_pk:hex() then
      passed = passed + 1
   else
      io.write("FAIL pubgen " .. name .. ": got " .. pk:hex() .. " expected " .. expected_pk:hex() .. "\n")
      failed = failed + 1
   end
end

-- Test sign matches known signature
local function check_sign(name, sk, msg, aux, expected_sig)
   local sig = schnorr.sign(sk, msg, aux)
   if sig:hex() == expected_sig:hex() then
      passed = passed + 1
   else
      io.write("FAIL sign " .. name .. ": got " .. sig:hex() .. " expected " .. expected_sig:hex() .. "\n")
      failed = failed + 1
   end
end

-- Test verify
local function check_verify(name, pk, msg, sig, expected)
   local result = schnorr.verify(pk, msg, sig)
   if result == expected then
      passed = passed + 1
   else
      io.write("FAIL verify " .. name .. ": got " .. tostring(result) .. " expected " .. tostring(expected) .. "\n")
      failed = failed + 1
   end
end

check_pubgen("vector 0", sk0, pk0)
check_pubgen("vector 1", sk1, pk1)
check_sign("vector 0", sk0, msg0, aux0, sig0)
check_sign("vector 1", sk1, msg1, aux1, sig1)
check_verify("vector 0", pk0, msg0, sig0, true)
check_verify("vector 1", pk1, msg1, sig1, true)

-- Negative test: wrong message fails
check_verify("bad msg", pk0, msg1, sig0, false)

-- Negative test: wrong public key fails
check_verify("bad pk", pk1, msg0, sig0, false)

io.write(string.format("BIP-340 vectors: %d passed, %d failed\n", passed, failed))
if failed > 0 then
   error("BIP-340 tests FAILED")
end
