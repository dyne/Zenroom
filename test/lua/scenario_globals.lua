load_scenario('zencode_ethereum')
load_scenario('zencode_reflow')
load_scenario('zencode_w3c')

assert(rawget(_G, 'ABC') == nil, 'zencode_reflow should not leak ABC')
assert(rawget(_G, 'G2') == nil, 'zencode_reflow should not leak G2')
assert(rawget(_G, 'JOSE') == nil, 'zencode_w3c should not leak JOSE')
assert(rawget(_G, 'weimult') == nil, 'zencode_ethereum should not leak weimult')
assert(rawget(_G, 'gweimult') == nil, 'zencode_ethereum should not leak gweimult')
assert(rawget(_G, 'res') == nil, 'global res should be unset before ethereum export')

local exported = ZEN.schemas.ethereum_method.export({
   name = O.from_string('transfer'),
   input = { O.from_string('address'), O.from_string('uint256') },
   output = { O.from_string('bool') },
})

assert(exported.name == 'transfer', 'ethereum method export should still work')
assert(exported.input[1] == 'address', 'ethereum method export should preserve inputs')
assert(exported.output[1] == 'bool', 'ethereum method export should preserve outputs')
assert(rawget(_G, 'res') == nil, 'ethereum method export should not leak res')

print('scenario globals regressions OK')
