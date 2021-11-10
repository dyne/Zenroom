BTC = require('crypto_bitcoin')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('1000000000')) == '10')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('100000000')) == '1')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('10000000')) == '0.1')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('1000000')) == '0.01')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('100000')) == '0.001')

assert(BTC.value_satoshi_to_btc(BIG.from_decimal('12345')) == '0.00012345')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('123456')) == '0.00123456')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('1234567')) == '0.01234567')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('12345678')) == '0.12345678')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('123456789')) == '1.23456789')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('1234567891')) == '12.34567891')

assert(BTC.value_satoshi_to_btc(BIG.from_decimal('12300000000')) == '123')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('12340000000')) == '123.4')
assert(BTC.value_satoshi_to_btc(BIG.from_decimal('12345000000')) == '123.45')

