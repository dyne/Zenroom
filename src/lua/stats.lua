--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2025 Dyne.org foundation
--designed, written and maintained by Alberto Lerda
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
--]]
-- Tables supplied as arguments are not changed.


-- Table to hold statistical functions
local stats={}

-- Get the mean value of a table
function stats.average( tab_in )
  local zero = BIG.new(0)
  local one = BIG.new(1)
  local sum = zero
  local count = zero 
  local newsum
  local t
  for _,v in pairs(tab_in) do
    t = type(v)
    if t == 'number' then
      v = BIG.from_decimal(tostring(v))
    elseif iszen(t) then
      v = BIG.from_decimal(v:octet():string())
    else
      error("Unknown type for number", 2)
    end
    if type(v) == 'zenroom.big' then
      newsum = sum + v
      count = count + one
      zencode_assert(newsum > sum, "Overflow in sum")
      sum = newsum
    end
  end
  zencode_assert(count > zero, "No numbers in array")

  return (sum / count)
end
-- Get the variance of a table
function stats.variance( tab_in )
  local zero = BIG.new(0)
  local one = BIG.new(1)
  local m
  local vm
  local sum = zero 
  local count = zero
  local result
  local t
  local newsum
  m = stats.average( tab_in )

  for _,v in pairs(tab_in) do
    t = type(v)

    if t == 'number' then
      v = BIG.from_decimal(tostring(v))
    elseif iszen(t) then
      v = BIG.from_decimal(v:octet():string())
    else
      error("Unknown type for number", 2)
    end
    if type(v) == 'zenroom.big' then
      vm = v - m
      newsum = sum + (vm * vm)
      zencode_assert(newsum > sum, "Overflow in sum")
      count = count + one
      sum = newsum
    end
  end

  zencode_assert(count > one, "Not enough numbers (at least 2)")
  result = sum / (count-one)

  return result
end

function stats.standardDeviation( t )
  return BIG.sqrt(stats.variance( t ))
end

return stats
