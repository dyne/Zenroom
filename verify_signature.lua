local ETH = require'crypto_ethereum'

-- DAO signature

local signature = {
  v= BIG.new(27),
  r= O.from_hex("482c1d99d254a69709b0f58471681f95dc39d654a942ddd783c213117b2a3ec7"),
  s= O.from_hex("0ca66722dc1090bf9fcf1c40d3e3554a5774bcd37e2bb4d6f3150a54aeb8e774"),
}
local address = O.from_hex("004B218B0caaC0285B321F9bA31564B182E0a770")
local daoAddress = O.from_hex("77c2f9730B6C3341e1B71F76ECF19ba39E88f247")
local daoVoteID = "234"

local typeSpec = {"address", "string"}
local dao = {daoAddress, daoVoteID}

-- Create message using ABI encoding
-- `When I create the eth ABI encoding of 'dao' using 'type spec'`

local message = ETH.abi_encode(typeSpec, dao)

-- zencode create hash ...

local H = HASH.new('keccak256')
local hash = H:process(message)

-- Verify the signature
-- `When I verify the 'message' has a ethereum signature in 'eth signature' by 'address'`
local ethersMessage = O.from_string("\x19Ethereum Signed Message:\n") .. O.new(#hash) .. hash

local hash = H:process(ethersMessage)

local valid = ETH.verify_signature_from_address(signature, address, fif(signature.v:parity(), 0, 1), hash)

assert(valid)



-- encoded signature from metamask
local address = O.from_hex("63eaf92f46b6c3e1e46d672de42f6016f8b1f661")
local msg = O.from_string("ciao peppe")
local sign = O.from_hex("96fe86c781b139d97117f2576c6e099236803fbdcd85cf7f6208551be9b69ab25646aebab2122abb8059e0d35ab8a90eb89d3c292d6027596e417f48126da22a1c")
local signature = {
  r = sign:sub(1,32),
  s = sign:sub(33, 64),
  v = BIG.new(sign:sub(65, 65))
}

-- Verify the signature
-- `When I verify the 'message' has a ethereum signature in 'eth signature' by 'address'`
local ethersMessage = O.from_string("\x19Ethereum Signed Message:\n") .. O.new(#msg) .. msg

local hash = H:process(ethersMessage)

local valid = ETH.verify_signature_from_address(signature, address, fif(signature.v:parity(), 0, 1), hash)

assert(valid)
