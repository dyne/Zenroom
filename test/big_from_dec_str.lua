assert(BIG.from_dec_str('1'):octet() == O.from_hex('01'))
assert(BIG.from_dec_str('10000'):octet() == O.from_hex('2710'))
assert(BIG.from_dec_str('3241234123454677858658653465435'):octet() == O.from_hex('28e8fe07152f8191d2f12e6b5b') )
assert(BIG.from_dec_str('908907679878905720234758926590204765297843'):octet() == O.from_hex('0a6f0a23bc79a6a46e27428337f35fbc5cb3'))
