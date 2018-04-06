--
-- Copy me if you can.
-- by parazyd
--


local clock = os.clock

function sleep(n) -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

wave = 0
t = {"*","*","*","*","*"," ","+","+","+"," "}

while true do
	print("")
	for j = 1, math.floor(math.sin(wave)*50+50) do
		io.write(" ")
	end
	for i = 1, 10 do
		io.write(t[i])
	end
	temp = t[1]
	table.remove(t, 1)
	table.insert(t, temp)
	wave = wave + 0.1
	sleep(0.025)
end
