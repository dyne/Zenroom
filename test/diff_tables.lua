t1 = {
	{fieldName = "bb", time = "1"},
	{fieldName = "cc", time = "3"},
	{fieldName = "cc", time = "1"},
	{fieldName = "ee", time = "2"}
}

t2 = {
	{fieldName = "aa", time = "1"},
	{fieldName = "bb", time = "1"},
	{fieldName = "cc", time = "2"},
	{fieldName = "cc", time = "3"}
}

function dump(t)
	for i,v in ipairs(t) do
		print(i, t1[i].fieldName)
		for j,w in pairs(v) do
			print("",w)
		end
	end
end


-- ===================================================================================
-- USAGE
-- formatting function
local fmt1 = function(s) return s:gsub("&","&"):gsub("'","'"):lower() end
local fmt2 = function(s) return s:gsub("&","&"):gsub("'","'"):lower() end
-- comparison function
local comparef = nil
-- CallBack function
local CBdupli = function(i1,i2) print(i1, t1[i1].fieldName," -> ",i2, t2[i2].fieldName) return true end
local CBonly1 = function(i)
   print("Only in first table:", i, t1[i].fieldName)
 end
local CBonly2 = function(i)
   print("Only in second table:", i, t2[i].fieldName)
end

-- res, counter = diff_tables(t1,t2, "ORDER BY fieldName, time desc" , {}, {}, fmt1, fmt2, nil, nil,CBonly1,CBonly2 )
res, counter = diff_tables(t1,t2, "ORDER BY fieldName, time desc")

print("Comparison Log: ")
dump(res)
print("Number of comparisons: ", counter)

