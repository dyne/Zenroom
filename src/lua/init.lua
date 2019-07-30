-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
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

-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()


-- default encoding base64url (RFC4648)
-- this is the fastest and most portable encoder in zenroom
_G["ENCODING"] = url64
-- ZEN = { assert = assert } -- zencode shim when not loaded
require('zenroom_common')
INSIDE = require('inspect')
OCTET  = require('zenroom_octet')
JSON   = require('zenroom_json')
ECDH   = require('zenroom_ecdh')
BIG    = require('zenroom_big')
HASH   = require('zenroom_hash')
O   = OCTET  -- alias
INT = BIG    -- alias
H   = HASH   -- alias
I   = INSIDE -- alias

ZEN = require('zencode')
-- import/export schema helpers
require('zencode_schemas')
-- base data functions
require('zencode_data')
