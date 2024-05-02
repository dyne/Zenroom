
local function debug( t )
   print( table.concat( t , " " ) )
end

local test1 = { 8 , 7 , 6 , 9 , -10 , 15 , 5 , 12 , 6 }

local test2 =
{
 -- 100 numbers, between 0~100.
 059,067,094,088,054,080,029,029,082,098,022,076,014,074,020,055,004,055,077,065,
 000,068,011,081,001,012,005,027,060,089,003,006,024,070,060,016,020,083,095,032,
 047,027,088,079,080,077,087,057,071,085,016,068,066,098,078,083,067,015,071,030,
 026,092,069,008,090,073,100,019,086,085,061,061,013,029,054,007,046,005,052,087,
 009,087,082,070,005,100,043,012,033,044,037,059,092,094,035,038,056,001,065,021,
}

local test3 =
{
  { k = 5 } , { k = 2 } , { k = 10 } , { k = 0 } , { k = 7 } , k = { 6 }
}

print( "QSORT Test #1:" )

QSORT( test1 )

debug( test1 )

print( "QSORT Test #2:" )

QSORT( test2 )

debug( test2 )

print( "QSORT Test #3: (Callback)" )

QSORT( test3 , function( a , b ) return a.k < b.k end )

local r = {}

for k , v in ipairs( test3 ) do
   r[ k ] = v.k ;
end

debug( r )



print'QSORT Test #4: table sorted by zenroom type keys (octets)'
claims = { "I am over 18",
		   "Born in Pescara",
		   "Resident in Pizzoferrato",
		   "C level English speaker",
		   "Elite Startfighter pilot" }
H = ECP.hashtopoint
mask = ECP.random()
hashed_claims = deepmap(H, claims)
masked_claims = { }
for _,v in sort_pairs(hashed_claims) do
   masked_claims[v] = v +  mask
end
for k,v in sort_pairs(masked_claims) do
   I.print({k=k,v=v})
end
