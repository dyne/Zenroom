-- Copyright (C) 2017 - DarkRoku12
-- Optimized version.

-- Stack slot #1 = t.
local function set2( t , i , j , ival , jval )
   t[ i ] = ival ; -- lua_rawseti(L, 1, i);
   t[ j ] = jval ; -- lua_rawseti(L, 1, j);
end

local function default_comp( a , b )
    local l, r
    if iszen(type(a)) then l = a:octet() else l = a end
    if iszen(type(b)) then r = b:octet() else r = b end
    return l < r
end

local auxsort ;

function auxsort( t , l , u , sort_comp )

   while l < u do 

      -- sort elements a[l], a[(l+u)/2] and a[u]

      do
         local a = t[ l ] -- lua_rawgeti(L, 1, l);
         local b = t[ u ] -- lua_rawgeti(L, 1, u);

         if sort_comp( b , a ) then
            set2( t , l , u , b , a ) -- /* swap a[l] - a[u] */
         end
      end

      if u - l == 1 then break end -- only 2 elements

      local i = math.floor( ( l + u ) / 2 ) ; -- -- for tail recursion (i).

      do
         local a = t[ i ] -- lua_rawgeti(L, 1, i);
         local b = t[ l ] -- lua_rawgeti(L, 1, l);

         if sort_comp( a , b ) then -- a[i] < a[l] ?
            set2( t , i , l , b , a )
         else
            b = nil -- remove a[l]
            b = t[ u ]
            if sort_comp( b , a ) then -- a[u]<a[i] ?
               set2( t , i , u , b , a )
            end
         end
      end

      if u - l == 2 then break end ; -- only 3 elements

      local P = t[ i ] -- Pivot.
      local P2 = P -- lua_pushvalue(L, -1);
      local b = t[ u - 1 ]

      set2( t , i , u - 1 , b , P2 )
      -- a[l] <= P == a[u-1] <= a[u], only need to sort from l+1 to u-2 */

      i = l ;

      local j = u - 1 ; -- for tail recursion (j).

      while true do -- for( ; ; )
         -- invariant: a[l..i] <= P <= a[j..u]
         -- repeat ++i until a[i] >= P

         i = i + 1 ; -- ++i
         local a = t[ i ] -- lua_rawgeti(L, 1, i)

         while sort_comp( a , P ) do
            i = i + 1 ; -- ++i
            a = t[ i ] -- lua_rawgeti(L, 1, i)
         end

         -- repeat --j until a[j] <= P

         j = j - 1 ; -- --j
         local b = t[ j ]

         while sort_comp( P , b ) do
            j = j - 1 ; -- --j
            b = t[ j ] -- lua_rawgeti(L, 1, j)
         end

         if j < i then
            break
         end

         set2( t , i , j , b , a )
      end -- End for.

      t[ u - 1 ] , t[ i ] = t[ i ] , t[ u - 1 ] ;

      -- a[l..i-1] <= a[i] == P <= a[i+1..u] */
      -- adjust so that smaller half is in [j..i] and larger one in [l..u] */

      if ( i - l ) < ( u - i ) then
         j = l ;
         i = i - 1 ;
         l = i + 2 ;
      else
         j = i + 1 ;
         i = u ;
         u = j - 2 ;
      end

      auxsort( t , j , i , sort_comp ) ;  -- call recursively the smaller one */

   end
   -- end of while
   -- repeat the routine for the larger one

end

-- sort function.
return function( t , comp )

   if type( t ) ~= "table" then
       error("QSort function argument not a table: "..type( t), 2)
   end

   if comp then
      if type( comp ) ~= "function" then
          error("QSort function argument not a function: "..type(comp), 2)
      end
   end

   auxsort( t , 1 , #t , comp or default_comp )

end
