####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
rm -f /tmp/zenroom-test-summary.txt

cat <<EOF >number.lua
function fib(n)
  if n <= 1 then
    return 1;
  else
    return fib(n-1) + fib(n-2);
  end
end
print(fib(tonumber(DATA)))
EOF

cat <<EOF >float.lua
function fib(n)
  local one = F.new(1)
  if n <= one then
    return one;
  else
    return fib(n-one) + fib(n-F.new(2));
  end
end
print(fib(F.new(DATA)))
EOF

cat <<EOF >big.lua
function fib(n)
  local one = BIG.new(1)
  if n <= one then
    return one;
  else
    return fib(n-one) + fib(n-INT.new(2));
  end
end
print(fib(INT.new(DATA)):decimal())
EOF

function bench() (
  [ -e "$1.dat" ] && rm "$1.dat"
  [ -d "tmp" ] || mkdir tmp
  for n in 5 10 15 20 25 30 35; do
    echo "$n" > "tmp/$1.data"
    TIME=`$Z $1.lua -a "tmp/$1.data" 2>&1 | perl -lne 'print $1 if /Time used: (\d+)/'`
    echo "$n,$TIME" >>"tmp/$1.dat"
    #$Z $1.lua -a "tmp/$1.data" 2>&1 
  done
)

bench number
bench float
bench big
