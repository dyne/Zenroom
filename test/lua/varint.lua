-- test varint conversions
VI = require'varint'

x0 = O.from_hex('00')
x127 = O.from_hex'7f'
x128 = O.from_hex'8001'
x255 = O.from_hex'ff01'
x16383 = O.from_hex'ff7f'
x16384 = O.from_hex'808001'
x2097151 = O.from_hex'ffff7f'
x2097152 = O.from_hex'80808001'

function Ci(h)
    return VI.read_i64(O.from_hex(h))
end

assert(VI.read_u64(x0) == 0)
assert(VI.read_u64(x127) == 127)
assert(VI.read_u64(x128) == 128)
assert(VI.read_u64(x255) == 255)
assert(VI.read_u64(x16383) == 16383)
assert(VI.read_u64(x16384) == 16384)
assert(VI.read_u64(x2097151) == 2097151)
assert(VI.read_u64(x2097152) == 2097152)

assert(VI.read_i64(O.from_hex'00') ==  0)
assert(VI.read_i64(O.from_hex'01') == -1)
assert(VI.read_i64(O.from_hex'02') ==  1)
assert(VI.read_i64(O.from_hex'03') == -2)
assert(VI.read_i64(O.from_hex'fe01') == 127)
assert(VI.read_i64(O.from_hex'7f') == -64)
assert(Ci'8002' == 128)
assert(Ci'ff01' == -128)
assert(Ci'8004' == 256)
assert(Ci'ff03' == -256)
assert(Ci'8010' == 1024)
-- assert(I.spy(Ci'ff1f') == -1024)
assert(Ci'feff03' == 32767)
assert(Ci'ffff03' == -32768)


num, oct = VI.read_u64(O.from_hex('8626'))
assert(oct:trim() == O.from_hex'1306')
