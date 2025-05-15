function sub(a,b,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(a) == "zenroom.big", "a is not a BIG")
    assert(type(b) == "zenroom.big", "b is not a BIG")
    if a:modsub(b,p):__eq(p) then 
        return big.new(0)
    else
        return a:modsub(b,p)
    end
end 


local function ckadd(a,b,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(a) == "zenroom.big", "a is not a BIG")
    assert(type(b) == "zenroom.big", "b is not a BIG")
    local r = a:__add(b):__mod(p)
    assert(r:__eq(b:__add(a):__mod(p)), "error in the field elements addition")
    local x = a:__add(big.new(1)):__mod(p)
    local y = b:__add(big.new(1)):__mod(p)
    local z = r:__add(big.new(2)):__mod(p)
    assert(z:__eq(x:__add(y):__mod(p)), "error in the field elements addition")
    assert((a:__mod(p)):__eq(sub(r,b,p)), "error in the field elements addition")
    assert((b:__mod(p)):__eq(sub(r,a,p)), "error in the field elements addition")
    return r 
end


local function cksub(a,b,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(a) == "zenroom.big", "a is not a BIG")
    assert(type(b) == "zenroom.big", "b is not a BIG")
    local r = sub(a,b,p)
    local x = a:__add(big.new(1)):__mod(p)
    local y = b:__add(big.new(1)):__mod(p)
    assert(r:__eq(sub(x,y,p)), "error in the field elements subtraction") 
    local mr = sub(b,a,p)
    assert(mr:__eq(sub(y,x,p)), "error in the field elements subtraction")
    assert(a:__eq(b:__add(r):__mod(p)), "error in the field elements subtraction")
    assert(b:__eq(a:__add(mr):__mod(p)), "error in the field elements subtraction")
    assert(big.new(0):__eq(r:__add(mr):__mod(p)), "error in the field elements subtraction")
    return r
end 

function of_string(s,p)
    local a = big.new(0) 
    local base = big.new(10)
    for i = 1, string.len(s) do 
        d = big.new(string.sub(s,i,i))
        a = a:modmul(base,p)
        a = a:__add(d):__mod(p)
    end 
    return a
end

local function fibonacci(p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local a = big.new(1)
    local b = big.new(1)

    for i = 1, 1000 do 
        a = ckadd(a,b,p)
        b = ckadd(b,a,p)
    end

    local s = "6835702259575806647045396549170580107055408029365524565407553367798082454408054014954534318953113802726603726769523447478238192192714526677939943338306101405105414819705664090901813637296453767095528104868264704914433529355579148731044685634135487735897954629842516947101494253575869699893400976539545740214819819151952085089538422954565146720383752121972115725761141759114990448978941370030912401573418221496592822626"
    assert(a:__eq(of_string(s,p)), "fibonacci() doesn't return the expected output")
end 


local p_1 = big.from_decimal("18446744073709551557")
local fib_1 = fibonacci(p_1)

function modinv_0(x,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(x) == "zenroom.big", "x is not a BIG")
    if x:__eq(big.new(0)) then
        return big.new(0)
    else
        return x:modinv(p)
    end 
end 

local function ckmul(a,b,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(a) == "zenroom.big", "a is not a BIG")
    assert(type(b) == "zenroom.big", "b is not a BIG")
    if a:__eq(big.new(0)) and b:__eq(big.new(0)) then 
        r = big.new(0)
    end
    r = a:modmul(b,p)
    assert(r, b:modmul(a,p))
    local ma = modinv_0(a,p)
    local mb = modinv_0(b,p)
    assert(r, ma:modmul(mb,p))
    assert(r, mb:modmul(ma,p))
    return r
end 

local function factorial(p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local a = big.new(1)
    local fi = big.new(1)
    for i = 1, 337 do
        a = ckmul(a, fi, p)
        fi = ckadd(fi, big.new(1), p)
    end 
    s = "130932804149088992546057261943598916651380085320056882046632369209980447366486195583875107499552077757320239493552004852577547570260331861859535521014367028762150336371971084184802220775697724840028097301334011793388942370614718341215113319703287766478296719019864501440605926667194653195515282444560161328301222855804492620971650056743347973226019758046208866500052558105710981673345457144935004205153930768986245233790635907756296677802809190469443074096751804464370890609618413796499897335752206338990966921419488285779097481797799327000523783874784902588031943372895509486862780297994201058534583425203348291866696425144320000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    assert(a:__eq(of_string(s,p)), "factorial() doesn't return the expected output")
end 


local function mult(p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    for i = 1, 10 do 
        for j = 1, 10 do 
            a = ckmul(big.new(i), big.new(j), p)
            assert(a:__eq(big.new(i*j):__mod(p)), "error in mult(), in particular in ckmul")
        end
    end
end 


local function inverse(p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    for i = 0, 999 do 
        local x = big.new(i)
        x = modinv_0(x,p)
        if i == 0 then
            a = ckmul(big.new(i),x,p)
            assert(a:__eq(big.new(0)), "error in inverse() function")
        else
            a = ckmul(big.new(i),x,p)
            assert(a:__eq(big.new(1)), "error in inverse() function")
        end
    end 
end 


local function neg(p)
    for i = 0, 999 do 
        local x = big.new(i)
        x = x:modneg(p)
        assert(ckadd(big.new(i),x,p):__eq(big.new(0)), "error in neg() function")
        assert(ckadd(big.new(i),big.new(i):modneg(p),p):__eq(big.new(0)), "error in neg() function")
    end 
end     

neg(p_1)
