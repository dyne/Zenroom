-- very simple test on octets shifts

for i=1,20 do
    local o = O.random(1000*i)
    local expected = string.rep("0", i)
    local sr = o >> i
    local sl = o << i
    local csr = o:shr_circular(i)
    local cls = o:shl_circular(i)
    assert(sl:bin():sub(1,#o:bin()-i)== o:bin():sub(i+1,#o:bin()))
    assert(expected == sl:bin():sub((#o:bin())-i +1,#o:bin()))
    assert(sr:bin():sub(i+1,#o:bin()) == o:bin():sub(1,#o:bin()-i))
    assert(expected == sr:bin():sub(1,i))
    assert(csr:bin():sub(i+1,#o:bin()) .. csr:bin():sub(1,i) == o:bin())
    assert(cls:bin():sub(#o:bin()-i+1,#o:bin()) .. cls:bin():sub(1,#o:bin()-i))
 end
