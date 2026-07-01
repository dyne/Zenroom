-- DEPRECATED: This file is a legacy zkcc wrapper.
-- Use require('niwi') instead, which calls the native lib/niwi bindings.
--
-- For backward compatibility during the transition, this file
-- re-exports the native niwi module.

local Niwi = {}

local native_niwi = require('niwi')
if native_niwi then
    Niwi = native_niwi
end

return Niwi
