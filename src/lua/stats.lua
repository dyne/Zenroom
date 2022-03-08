--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
--designed, written and maintained by Alberto Lerda
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--]]
-- Tables supplied as arguments are not changed.


-- Table to hold statistical functions
stats={}

-- Get the mean value of a table
function stats.average( t )
  local zero = BIG.new(0)
  local one = BIG.new(1)
  local sum = zero
  local count = zero 

  for k,v in pairs(t) do
    local t = type(v)
    if t == 'number' then
      v = BIG.from_decimal(tostring(v))
    elseif iszen(t) then
      v = BIG.from_decimal(v:octet():string())
    else
      error("Unknown type for number", 2)
    end
    if type(v) == 'zenroom.big' then
      local newsum = sum + v
      count = count + one
      ZEN.assert(newsum > sum, "Overflow in sum")
      sum = newsum
    end
  end
  ZEN.assert(count > zero, "No numbers in array")

  return (sum / count)
end
-- Get the variance of a table
function stats.variance( t )
  local zero = BIG.new(0)
  local one = BIG.new(1)
  local m
  local vm
  local sum = zero 
  local count = zero
  local result

  m = stats.average( t )

  for k,v in pairs(t) do
    local t = type(v)

    if t == 'number' then
      v = BIG.from_decimal(tostring(v))
    elseif iszen(t) then
      v = BIG.from_decimal(v:octet():string())
    else
      error("Unknown type for number", 2)
    end
    if type(v) == 'zenroom.big' then
      local newsum
      vm = v - m
      newsum = sum + (vm * vm)
      ZEN.assert(newsum > sum, "Overflow in sum")
      count = count + one
      sum = newsum
    end
  end

  ZEN.assert(count > one, "Not enough numbers (at least 2)")
  result = sum / (count-one)

  return result
end

function stats.standardDeviation( t )
  return BIG.sqrt(stats.variance( t ))
end

return stats
