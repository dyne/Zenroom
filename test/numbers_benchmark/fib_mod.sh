####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
rm -f /tmp/zenroom-test-summary.txt

cat <<EOF >number.lua
function fib(n)
  limit = 1000
  a=0
  b=1
  for i=1,n,1 do
    a,b=b,a+b
    if a >= limit then
      a = a - limit
    end
    if b >= limit then
      b = b - limit
    end
  end
  return b
end
print("Result: " .. fib(tonumber(DATA)))
EOF

cat <<EOF >big.lua
function fib(n)
  limit = BIG.new(1000)
  a=BIG.new(0)
  b=BIG.new(1)
  for i=1,n,1 do
    a,b=b,a+b
    if limit <= a then
      a = a - limit
    end
    if limit <= b then
      b = b - limit
    end
  end
  return b
end
print("Result: " .. fib(tonumber(DATA)):decimal())
EOF

cat <<EOF >float.lua
function fib(n)
  limit = F.new(1000)
  a=F.new(0)
  b=F.new(1)
  for i=1,n,1 do
    a,b=b,a+b
    if limit <= a then
      a = a - limit
    end
    if limit <= b then
      b = b - limit
    end
  end
  return b
end
print("Result: " .. tostring(fib(tonumber(DATA))))
EOF

function bench() (
  [ -d "tmp" ] || mkdir tmp
  [ -e "tmp/$1.dat" ] && rm "tmp/$1.dat"
  for n in $(seq 5 5 1000); do
    echo "$n" > "tmp/$1.data"
    out=`$Z $1.lua -a "tmp/$1.data" 2>&1`

    RES=`echo $out | perl -lne 'print $1 if /Result: ([e-\d\.]+)/'`
    TIME=`echo $out | perl -lne 'print $1 if /Time used: (\d+)/'`
    echo "$n,$TIME,$RES" >>"tmp/$1.dat"
  done
)

bench number
bench float
bench big
