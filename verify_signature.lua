local ETH = require'crypto_ethereum'
local signature = {
  v= 27,
  r= O.from_hex("d3cd7fee49e27523dd8d696f35ad32385df2ea21a1dd96d3ffa11b891a81ee6f"),
  s= O.from_hex("63427589459c8af1fe19f2d85be90fe88ad530f5cb6c78d22edba3fa455bfda4"),
}
local address = O.from_hex("37F73cA1e28C6624f2b27ef26F7A97521A621279")

local daoAddress = O.from_hex("77c2f9730B6C3341e1B71F76ECF19ba39E88f247")
local daoVoteID = "234"

local typeSpec = {"address", "string"}
local dao = {daoAddress, daoVoteID}

-- Create message using ABI encoding
-- `When I create the eth ABI encoding of 'dao' using 'type spec'`

local message = ETH.abi_encode(typeSpec, dao)

-- Verify the signature
-- `When I verify the ethereum signature 'message' from 'address'`

local H = HASH.new('keccak256')
local hash = H:process(message)

local ethersMessage = O.from_string("\x19Ethereum Signed Message:\n") .. O.new(#hash) .. hash

hash = H:process(ethersMessage)

local valid = ETH.verify_signature_from_address(signature, address, fif(signature.v % 2 == 0, 0, 1), hash)

I.spy(valid)
