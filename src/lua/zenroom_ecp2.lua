--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

local ecp2 = require'ecp2'
require'fp12' -- FP12 implicit

function ecp2.hashtopoint(s)
   return ecp2.mapit(sha512(s))
end

function ecp2.random()
   return ecp2.mapit(OCTET.random(64))
end

return ecp2
