-- Reusable RPBSch relation context ownership smoke test.

local niwi = require'crypto_niwi'

assert(niwi, 'crypto_niwi module not loaded')
local first = niwi.prepare_rpbsch_relation()
assert(first == niwi.prepare_rpbsch_relation(),
       'RPBSch context must be cached per Lua VM')
first = nil
collectgarbage('collect')
assert(niwi.prepare_rpbsch_relation(),
       'RPBSch context must remain valid until VM teardown')
print('RPBSch reusable context smoke test passed')
