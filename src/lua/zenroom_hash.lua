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

local hash = require'hash'

-- when using facility functions, global hashers are created only once
SHA256 = nil
SHA512 = nil
function sha256(data)
   if SHA256==nil then SHA256 = hash.new('sha256') end -- optimization
   return SHA256:process(data)
end
function sha512(data)
   if SHA512==nil then SHA512 = hash.new('sha512') end -- optimization
   return SHA512:process(data)
end

return hash
