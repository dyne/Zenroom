-- Taken from https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki

-- TODO: The tests output the scriptPubKey

local BTC = require('crypto_bitcoin')

assert(O.from_hex('0014') .. BTC.read_bech32_address('BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4') == O.from_hex('0014751e76e8199196d454941c45d1b3a323f1433bd6'))
--assert(BTC.read_bech32_address('tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7') == O.from_hex('00201863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262')))
--assert(BTC.read_bech32_address('bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7k7grplx') == O.from_hex('5128751e76e8199196d454941c45d1b3a323f1433bd6751e76e8199196d454941c45d1b3a323f1433bd6'))
--assert(BTC.read_bech32_address('BC1SW50QA3JX3S') == O.from_hex('6002751e'))
--assert(BTC.read_bech32_address('bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj') == O.from_hex('5210751e76e8199196d454941c45d1b3a323'))
--assert(BTC.read_bech32_address('tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy') == O.from_hex('0020000000c4a5cad46221b2a187905e5266362b99d5e91c6ce24d165dab93e86433'))
