-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2026 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

-- NIWI Lua adapter — wraps lib/niwi native bindings.
--
-- Production interface:
--   local niwi = require('niwi')
--   proof = niwi.prove_circuit_niwi{ circuit=..., inputs=... }
--   ok    = niwi.verify_circuit_niwi{ circuit=..., proof=..., public_inputs=... }
--   info  = niwi.niwi_profile()
--
-- This replaces the legacy niwi/niwi.lua wrapper that used only the
-- legacy zkcc prove_circuit/verify_circuit functions.
--
-- When the native niwi module is not available (e.g. built without ZKCC),
-- require('niwi') will return nil and callers should check.

local native = require('niwi')

if not native then
    return nil
end

-- Niwi is a direct re-export of the native bindings.
-- We don't add wrapper logic here — all validation and error handling
-- is done in the C layer.
local Niwi = {}

-- Production API
Niwi.prove_circuit_niwi  = native.prove_circuit_niwi
Niwi.verify_circuit_niwi = native.verify_circuit_niwi
Niwi.niwi_profile         = native.niwi_profile

-- Test-only API (available only in DEBUG/test builds)
if native.prove_with_observation_test then
    Niwi.prove_with_observation_test = native.prove_with_observation_test
end
if native.extract_from_gamma_test then
    Niwi.extract_from_gamma_test = native.extract_from_gamma_test
end

-- Protocol metadata
Niwi.PROTOCOL_VERSION = native.PROTOCOL_VERSION
Niwi.VERSION = native.PROTOCOL_VERSION  -- alias

return Niwi
