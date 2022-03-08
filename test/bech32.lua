-- Taken from https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
-- Test modified to look only at the address
local BTC = require('crypto_bitcoin')

local addr, ver = O.from_segwit('BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4')
assert(addr == O.from_hex('751e76e8199196d454941c45d1b3a323f1433bd6') and ver == 0)
local addr, ver = O.from_segwit('tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7')
assert(addr == O.from_hex('1863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262') and ver == 0)
local addr, ver = O.from_segwit('bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kt5nd6y')
assert(addr == O.from_hex('751e76e8199196d454941c45d1b3a323f1433bd6751e76e8199196d454941c45d1b3a323f1433bd6') and ver == 1)
local addr, ver = O.from_segwit('BC1SW50QGDZ25J')
assert(addr == O.from_hex('751e') and ver == 16)
--assert(BTC.read_bech32_address('bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj') == O.from_hex('5210751e76e8199196d454941c45d1b3a323'))
--assert(BTC.read_bech32_address('tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy') == O.from_hex('0020000000c4a5cad46221b2a187905e5266362b99d5e91c6ce24d165dab93e86433'))

assert(O.from_hex('751e76e8199196d454941c45d1b3a323f1433bd6'):segwit(0, 'bc') == string.lower('BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4'))
assert(O.from_hex('1863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262'):segwit(0, 'TB') == string.lower('tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7'))
assert(O.from_hex('751e76e8199196d454941c45d1b3a323f1433bd6751e76e8199196d454941c45d1b3a323f1433bd6'):segwit(1, 'Bc') == string.lower('bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kt5nd6y'))
assert(O.from_hex('751e'):segwit(16, 'bC') == string.lower('BC1SW50QGDZ25J'))

print('=== There is supposed to be an error here:')
assert(O.from_hex('751e76e8199196d454941c45d1b3a323f1433bd6'):segwit(0, 'bc1') == false)
