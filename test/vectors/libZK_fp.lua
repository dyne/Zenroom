print("TEST VECTORS from Frigo's RFC: fp_test")

function sub(a,b,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(a) == "zenroom.big", "a is not a BIG")
    assert(type(b) == "zenroom.big", "b is not a BIG")
    if a:modsub(b,p):__eq(p) then 
        return big.new(0)
    else
        return a:modsub(b,p):__mod(p)
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
    assert(type(p) == "zenroom.big", "p is not a BIG")
    for i = 0, 999 do 
        local x = big.new(i)
        x = x:modneg(p)
        assert(ckadd(big.new(i),x,p):__eq(big.new(0)), "error in neg() function")
        assert(ckadd(big.new(i),big.new(i):modneg(p),p):__eq(big.new(0)), "error in neg() function")
    end 
end     

local function wraparound(p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local k = 32
    local f2k = 2*k
    for i = -k, k do 
        for j = -k, k do 
            fi = sub(big.new(f2k),big.new(i+2*k),p)
            fj = sub(big.new(f2k),big.new(j+2*k),p)
            fa = sub(big.new(f2k),big.new(i+j+2*k),p)
            fs = sub(big.new(f2k),big.new(i-j+2*k),p)
            a = ckadd(fi,fj,p)
            s = cksub(fi,fj,p)
            assert(a:__eq(fa), "error in wraparound() function")
            assert(s:__eq(fs), "error in wraparound() function")  
        end 
    end
end 

--create two tables with 6 elements. in the second one there are the inverses of the previous one
function evaluation_point(p) 
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local kNPolyEvaluationPoints = 6;
    poly_evaluation_point_ = {}
    inv_small_scalars= {}
    for i = 0, kNPolyEvaluationPoints-1 do 
        poly_evaluation_point_[i+1] = big.new(i)
        if (i == 0) then
            inv_small_scalars[i+1] = big.new(0)
        else 
            inv_small_scalars[i+1] = poly_evaluation_point_[i+1]:modinv(p)
        end 
    end
    return poly_evaluation_point_, inv_small_scalars
end 

--return an element of the first output of evaluation_point() function
function poly_evaluation_point(j,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local kNPolyEvaluationPoints = 6;
    assert(j<=kNPolyEvaluationPoints, "j>kNPolyEvaluationPoints")
    poly_ev, inv_scal = evaluation_point(p)
    return poly_ev[j]
end

--return an element of the second output of evaluation_point() function
--return (X[k] - X[k - i])^{-1}, were X[i] is the i-th poly evalaluation point.
function newton_denominator(k,i,p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local kNPolyEvaluationPoints = 6;
    assert(k<=kNPolyEvaluationPoints, "k>kNPolyEvaluationPoints")
    assert(i<=k, "i>k")
    assert(k~=(k-i), "k=(k-i)" )
    poly_ev, inv_scal = evaluation_point(p)
    return inv_scal[i]
end 


local function poly_evaluation_points(p)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local kNPolyEvaluationPoints = 6;
    for i = 1, kNPolyEvaluationPoints do 
        for j = 1, kNPolyEvaluationPoints do 
            if i ~= j then
                assert(poly_evaluation_point(i,p) ~= poly_evaluation_point(j,p), "error in the poly_evaluation_points() function") 
            end
        end
    end
    for i = 2, kNPolyEvaluationPoints-1 do 
        for k = kNPolyEvaluationPoints, i+1, -1 do 
            dx = sub(poly_evaluation_point(k,p),poly_evaluation_point(k-i+1,p),p)
            assert(big.new(1):__eq(dx:modmul(newton_denominator(k,i,p),p)), "error in poly_evaluation_points() function") 
        end 
    end
end 

local function onefield(p)
    mult(p)
    factorial(p)
    fibonacci(p)
    wraparound(p)
    neg(p)
    inverse(p)
    poly_evaluation_points(p)
end 

local function test_Fp_Allsizes()
    local prime_element = {
        big.from_decimal("18446744073709551557"),
        big.from_decimal("340282366920938463463374607431768211297"),
        big.from_decimal("6277101735386680763835789423207666416102355444464034512659"),
        big.from_decimal("115792089237316195423570985008687907853269984665640564039457584007913129639747"),
        big.from_decimal("2135987035920910082395021706169552114602704522356652769947041607822219725780640550022962086936379"),
        big.from_decimal("39402006196394479212279040100143613805079739270465446667948293404245721771497210611414266254884915640806627990306499"),
        --prime for Fp256
        big.from_decimal("115792089210356248762697446949407573530086143415290314195533631308867097853951"),
        --prime for Fp128
        big.from_decimal("340282042402384805036647824275747635201")
    }

    for i, p in ipairs(prime_element) do
        onefield(p)
    end 
    return("OK test Fp AllSizes")
end

print(test_Fp_Allsizes())

local function RootOfUnity_test()
    local p = big.from_decimal("21888242871839275222246405745257275088548364400416034343698204186575808495617")
    local omega = of_string("19103219067921713944291392827692070036145651957329286315305642004821462161904",p)
    for i = 1, 28 do 
        assert(omega ~= big.new(1), "error in the root of unity test")
        omega = omega:modmul(omega,p)
    end 
    assert(omega:__eq(big.new(1)), "error in the root of unity test")
    return("OK test root of unity")
end 

print(RootOfUnity_test())

local function InverseSecp256k1()
    local p = big.from_decimal("115792089237316195423570985008687907853269984665640564039457584007908834671663")
    --invert a bunch of powers of two
    local t = big.new(1)
    for i = 1, 1000 do 
        ti = t:modinv(p)
        one = t:modmul(ti, p)
        assert(one:__eq(big.new(1)), "error in the InverseSecp256k1 test")
        tii = ti:modinv(p)
        assert(t:__eq(tii), "error in the InverseSecp256k1 test")
        t = t:__add(t):__mod(p)
    end 
    return ("OK inverse test")
end 

print(InverseSecp256k1())

function of_bytes(byte_table,p)
    local little_endian = ""
    for i = #byte_table, 1, -1 do
        little_endian = little_endian .. string.format("%02X", byte_table[i])
    end
    local num = big.new(hex (little_endian))
    if num:__lte(p) then 
        return true
    else 
        return false
    end 
end 

local function castable()
    local p = big.from_decimal("115792089237316195423570985008687907853269984665640564039457584007908834671663")
    local b = {0xDD, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
               0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
               0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
               0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}
    assert(of_bytes(b,p) == false, "error in of_bytes() function")
    b[32] = 0xEF
    assert(of_bytes(b,p) == true, "error in of_bytes() function")
    return ("OK castable test")
end

print(castable())
