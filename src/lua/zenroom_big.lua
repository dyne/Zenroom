--[[
--This file is part of zenroom
--
--Copyright (C) 2022-2025 Dyne.org foundation
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
--Last modified by Matteo Cristino
--on Monday, 22th December 2025
--]]

local big = require'big'
-- optimization: we could implement it in C
function big.sqrt(num)
  local two = BIG.new(2)
  local xn = num
  local xnn;

  if xn ~= BIG.new(0) then
    xnn = (xn + (num / xn)) / two
    while xnn < xn do
      xn = xnn
      xnn = (xn + (num / xn)) / two
    end
  end


  return xn
  
end

return big
