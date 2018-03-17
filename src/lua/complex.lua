--[[
 
LUA MODULE
 
   complex v$(_VERSION) - complex numbers implemented as Lua tables
 
SYNOPSIS

  local complex = require 'complex'
  local cx1 = complex "2+3i" -- or complex.new(2, 3) 
  local cx2 = complex "3+2i"
  assert( complex.add(cx1,cx2) == complex "5+5i" )
  assert( tostring(cx1) == "2+3i" )
 
DESCRIPTION
 
  'complex' provides common tasks with complex numbers

   function complex.to( arg ); complex( arg )
   returns a complex number on success, nil on failure
   arg := number or { number,number } or ( "(-)<number>" and/or "(+/-)<number>i" )
      e.g. 5; {2,3}; "2", "2+i", "-2i", "2^2*3+1/3i"
      note: 'i' is always in the numerator, spaces are not allowed

  A complex number is defined as Cartesian complex number
  complex number := { real_part, imaginary_part } .
  This gives fast access to both parts of the number for calculation.
  The access is faster than in a hash table
  The metatable is just an add on.  When it comes to speed, one is faster using a direct function call.

API

  See code and test_complex.lua.

DEPENDENCIES

  None (other than Lua 5.1 or 5.2).
  
HOME PAGE
  
  http://luamatrix.luaforge.net
  http://lua-users.org/wiki/LuaMatrix

DOWNLOAD/INSTALL

  ./util.mk
  cd tmp/*
  luarocks make
  
 Licensed under the same terms as Lua itself.
 
  Developers:
    Michael Lutz (chillcode)
    David Manura http://lua-users.org/wiki/DavidManura (maintainer)
--]]

--/////////////--
--// complex //--
--/////////////--

-- link to complex table
local complex = {_TYPE='module', _NAME='complex', _VERSION='0.3.3.20111212'}

-- link to complex metatable
local complex_meta = {}

-- helper functions for parsing complex number strings.
local function parse_scalar(s, pos0)
	local x, n, pos = s:match('^([+-]?[%d%.]+)(.?)()', pos0)
	if not x then return end
	if n == 'e' or n == 'E' then
		local x2, n2, pos2 = s:match('^([+-]?%d+)(.?)()', pos)
		if not x2 then error 'number format error' end
		x = tonumber(x..n..x2)
		if not x then error 'number format error' end
		return x, n2, pos2
	else
		x = tonumber(x)
		if not x then error 'number format error' end
		return x, n, pos
	end
end
local function parse_component(s, pos0)
	local x, n, pos = parse_scalar(s, pos0)
	if not x then
		local x2, n2, pos2 = s:match('^([+-]?)(i)()$', pos0)
		if not x2 then error 'number format error' end
		return (x2=='-' and -1 or 1), n2, pos2
	end
	if n == '/' then
		local x2, n2, pos2 = parse_scalar(s, pos)
		x = x / x2
		return x, n2, pos2
	end
	return x, n, pos
end
local function parse_complex(s)
	local x, n, pos = parse_component(s, 1)
	if n == '+' or n == '-' then
		local x2, n2, pos2 = parse_component(s, pos)
		if n2 ~= 'i' or pos2 ~= #s+1 then error 'number format error' end
		if n == '-' then x2 = - x2 end
		return x, x2
	elseif n == '' then
		return x, 0
	elseif n == 'i' then
		if pos ~= #s+1 then error 'number format error' end
		return 0, x
	else
		error 'number format error'
	end
end

-- complex.to( arg )
-- return a complex number on success
-- return nil on failure
function complex.to( num )
	-- check for table type
	if type( num ) == "table" then
		-- check for a complex number
		if getmetatable( num ) == complex_meta then
			return num
		end
		local real,imag = tonumber( num[1] ),tonumber( num[2] )
		if real and imag then
			return setmetatable( { real,imag }, complex_meta )
		end
		return
	end
	-- check for number
	local isnum = tonumber( num )
	if isnum then
		return setmetatable( { isnum,0 }, complex_meta )
	end
	if type( num ) == "string" then
		local real, imag = parse_complex(num)
		return setmetatable( { real, imag }, complex_meta )
	end
end

-- complex( arg )
-- same as complex.to( arg )
-- set __call behaviour of complex
setmetatable( complex, { __call = function( _,num ) return complex.to( num ) end } )

-- complex.new( real, complex )
-- fast function to get a complex number, not invoking any checks
function complex.new( ... )
	return setmetatable( { ... }, complex_meta )
end

-- complex.type( arg )
-- is argument of type complex
function complex.type( arg )
	if getmetatable( arg ) == complex_meta then
		return "complex"
	end
end

-- complex.convpolar( r, phi )
-- convert polar coordinates ( r*e^(i*phi) ) to carthesic complex number
-- r (radius) is a number
-- phi (angle) must be in radians; e.g. [0 - 2pi]
function complex.convpolar( radius, phi )
	return setmetatable( { radius * math.cos( phi ), radius * math.sin( phi ) }, complex_meta )
end

-- complex.convpolardeg( r, phi )
-- convert polar coordinates ( r*e^(i*phi) ) to carthesic complex number
-- r (radius) is a number
-- phi must be in degrees; e.g. [0 - 360 deg]
function complex.convpolardeg( radius, phi )
	phi = phi/180 * math.pi
	return setmetatable( { radius * math.cos( phi ), radius * math.sin( phi ) }, complex_meta )
end

--// complex number functions only

-- complex.tostring( cx [, formatstr] )
-- to string or real number
-- takes a complex number and returns its string value or real number value
function complex.tostring( cx,formatstr )
	local real,imag = cx[1],cx[2]
	if formatstr then
		if imag == 0 then
			return string.format( formatstr, real )
		elseif real == 0 then
			return string.format( formatstr, imag ).."i"
		elseif imag > 0 then
			return string.format( formatstr, real ).."+"..string.format( formatstr, imag ).."i"
		end
		return string.format( formatstr, real )..string.format( formatstr, imag ).."i"
	end
	if imag == 0 then
		return real
	elseif real == 0 then
		return ((imag==1 and "") or (imag==-1 and "-") or imag).."i"
	elseif imag > 0 then
		return real.."+"..(imag==1 and "" or imag).."i"
	end
	return real..(imag==-1 and "-" or imag).."i"
end

-- complex.print( cx [, formatstr] )
-- print a complex number
function complex.print( ... )
	print( complex.tostring( ... ) )
end

-- complex.polar( cx )
-- from complex number to polar coordinates
-- output in radians; [-pi,+pi]
-- returns r (radius), phi (angle)
function complex.polar( cx )
	return math.sqrt( cx[1]^2 + cx[2]^2 ), math.atan2( cx[2], cx[1] )
end

-- complex.polardeg( cx )
-- from complex number to polar coordinates
-- output in degrees; [-180, 180 deg]
-- returns r (radius), phi (angle)
function complex.polardeg( cx )
	return math.sqrt( cx[1]^2 + cx[2]^2 ), math.atan2( cx[2], cx[1] ) / math.pi * 180
end

-- complex.norm2( cx )
-- multiply with conjugate, function returning a scalar number
-- norm2(x + i*y) returns x^2 + y^2
function complex.norm2( cx )
	return cx[1]^2 + cx[2]^2
end

-- complex.abs( cx )
-- get the absolute value of a complex number
function complex.abs( cx )
	return math.sqrt( cx[1]^2 + cx[2]^2 )
end

-- complex.get( cx )
-- returns real_part, imaginary_part
function complex.get( cx )
	return cx[1],cx[2]
end

-- complex.set( cx, real, imag )
-- sets real_part = real and imaginary_part = imag
function complex.set( cx,real,imag )
	cx[1],cx[2] = real,imag
end

-- complex.is( cx, real, imag )
-- returns true if, real_part = real and imaginary_part = imag
-- else returns false
function complex.is( cx,real,imag )
	if cx[1] == real and cx[2] == imag then
		return true
	end
	return false
end

--// functions returning a new complex number

-- complex.copy( cx )
-- copy complex number
function complex.copy( cx )
	return setmetatable( { cx[1],cx[2] }, complex_meta )
end

-- complex.add( cx1, cx2 )
-- add two numbers; cx1 + cx2
function complex.add( cx1,cx2 )
	return setmetatable( { cx1[1]+cx2[1], cx1[2]+cx2[2] }, complex_meta )
end

-- complex.sub( cx1, cx2 )
-- subtract two numbers; cx1 - cx2
function complex.sub( cx1,cx2 )
	return setmetatable( { cx1[1]-cx2[1], cx1[2]-cx2[2] }, complex_meta )
end

-- complex.mul( cx1, cx2 )
-- multiply two numbers; cx1 * cx2
function complex.mul( cx1,cx2 )
	return setmetatable( { cx1[1]*cx2[1] - cx1[2]*cx2[2],cx1[1]*cx2[2] + cx1[2]*cx2[1] }, complex_meta )
end

-- complex.mulnum( cx, num )
-- multiply complex with number; cx1 * num
function complex.mulnum( cx,num )
	return setmetatable( { cx[1]*num,cx[2]*num }, complex_meta )
end

-- complex.div( cx1, cx2 )
-- divide 2 numbers; cx1 / cx2
function complex.div( cx1,cx2 )
	-- get complex value
	local val = cx2[1]^2 + cx2[2]^2
	-- multiply cx1 with conjugate complex of cx2 and divide through val
	return setmetatable( { (cx1[1]*cx2[1]+cx1[2]*cx2[2])/val,(cx1[2]*cx2[1]-cx1[1]*cx2[2])/val }, complex_meta )
end

-- complex.divnum( cx, num )
-- divide through a number
function complex.divnum( cx,num )
	return setmetatable( { cx[1]/num,cx[2]/num }, complex_meta )
end

-- complex.pow( cx, num )
-- get the power of a complex number
function complex.pow( cx,num )
	if math.floor( num ) == num then
		if num < 0 then
			local val = cx[1]^2 + cx[2]^2
			cx = { cx[1]/val,-cx[2]/val }
			num = -num
		end
		local real,imag = cx[1],cx[2]
		for i = 2,num do
			real,imag = real*cx[1] - imag*cx[2],real*cx[2] + imag*cx[1]
		end
		return setmetatable( { real,imag }, complex_meta )
	end
	-- we calculate the polar complex number now
	-- since then we have the versatility to calc any potenz of the complex number
	-- then we convert it back to a carthesic complex number, we loose precision here
	local length,phi = math.sqrt( cx[1]^2 + cx[2]^2 )^num, math.atan2( cx[2], cx[1] )*num
	return setmetatable( { length * math.cos( phi ), length * math.sin( phi ) }, complex_meta )
end

-- complex.sqrt( cx )
-- get the first squareroot of a complex number, more accurate than cx^.5
function complex.sqrt( cx )
	local len = math.sqrt( cx[1]^2+cx[2]^2 )
	local sign = (cx[2]<0 and -1) or 1
	return setmetatable( { math.sqrt((cx[1]+len)/2), sign*math.sqrt((len-cx[1])/2) }, complex_meta )
end

-- complex.ln( cx )
-- natural logarithm of cx
function complex.ln( cx )
	return setmetatable( { math.log(math.sqrt( cx[1]^2 + cx[2]^2 )),
		math.atan2( cx[2], cx[1] ) }, complex_meta )
end

-- complex.exp( cx )
-- exponent of cx (e^cx)
function complex.exp( cx )
	local expreal = math.exp(cx[1])
	return setmetatable( { expreal*math.cos(cx[2]), expreal*math.sin(cx[2]) }, complex_meta )
end

-- complex.conjugate( cx )
-- get conjugate complex of number
function complex.conjugate( cx )
	return setmetatable( { cx[1], -cx[2] }, complex_meta )
end

-- complex.round( cx [,idp] )
-- round complex numbers, by default to 0 decimal points
function complex.round( cx,idp )
	local mult = 10^( idp or 0 )
	return setmetatable( { math.floor( cx[1] * mult + 0.5 ) / mult,
		math.floor( cx[2] * mult + 0.5 ) / mult }, complex_meta )
end

--// variables
complex.zero = complex.new(0, 0)
complex.one  = complex.new(1, 0)

--// metatable functions

complex_meta.__add = function( cx1,cx2 )
	local cx1,cx2 = complex.to( cx1 ),complex.to( cx2 )
	return complex.add( cx1,cx2 )
end
complex_meta.__sub = function( cx1,cx2 )
	local cx1,cx2 = complex.to( cx1 ),complex.to( cx2 )
	return complex.sub( cx1,cx2 )
end
complex_meta.__mul = function( cx1,cx2 )
	local cx1,cx2 = complex.to( cx1 ),complex.to( cx2 )
	return complex.mul( cx1,cx2 )
end
complex_meta.__div = function( cx1,cx2 )
	local cx1,cx2 = complex.to( cx1 ),complex.to( cx2 )
	return complex.div( cx1,cx2 )
end
complex_meta.__pow = function( cx,num )
	if num == "*" then
		return complex.conjugate( cx )
	end
	return complex.pow( cx,num )
end
complex_meta.__unm = function( cx )
	return setmetatable( { -cx[1], -cx[2] }, complex_meta )
end
complex_meta.__eq = function( cx1,cx2 )
	if cx1[1] == cx2[1] and cx1[2] == cx2[2] then
		return true
	end
	return false
end
complex_meta.__tostring = function( cx )
	return tostring( complex.tostring( cx ) )
end
complex_meta.__concat = function( cx,cx2 )
	return tostring(cx)..tostring(cx2)
end
-- cx( cx, formatstr )
complex_meta.__call = function( ... )
	print( complex.tostring( ... ) )
end
complex_meta.__index = {}
for k,v in pairs( complex ) do
	complex_meta.__index[k] = v
end

return complex

--///////////////--
--// chillcode //--
--///////////////--
