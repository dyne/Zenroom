set -e
# set -o pipefail

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

cookbook="../../docs/examples/zencode_cookbook"

# RNGFAKE="00"

detect_zenroom_path() {
	if [ ! -z $ZENROOM ]; then
		echo $ZENROOM
		exit 0
	fi
	zenroom_paths=( "$PWD" "$PWD/../../src" "$PWD/../src" "$PWD/src"
					"/usr/local/bin" "/usr/bin" "/bin" "$PWD/../.." "$PWD/..")
	zenroom_path="/usr/local/bin/zenroom"
	case $OSTYPE in
		linux*)
			zenroom_name="zenroom-linux-amd64"
			case `uname -m` in
				i686) zenroom_name="zenroom-linux-i386" ;;
				i386) zenroom_name="zenroom-linux-i386" ;;
				arm*) zenroom_name="zenroom-linux-armhf" ;;
				aarch64) zenroom_name="zenroom-linux-aarch64" ;;
			esac
			for p in "${zenroom_paths[@]}"; do
				if test -r "$p/$zenroom_name"; then zenroom_path="$p/$zenroom_name"; break; fi
				if test -r "$p/zenroom"; then zenroom_path="$p/zenroom"; break; fi
			done
			unset zenroom_name
		;;
		darwin*)
			for p in "${zenroom_paths[@]}"; do
				if test -r "$p/zenroom-osx.command"; then zenroom_path="$p/zenroom-osx.command"; break; fi
				if test -r "$p/zenroom.command"; then zenroom_path="$p/zenroom.command"; break; fi
				if test -r "$p/zenroom"; then zenroom_path="$p/zenroom"; break; fi
			done
		;;
		cygwin*|msys*|win32*)
			for p in "${zenroom_paths[@]}"; do
				if test -r "$p/zenroom.exe"; then zenroom_path="$p/zenroom.exe"; break; fi
			done
		;;
		bsd*)
			for p in "${zenroom_paths[@]}"; do
				if test -r "$p/zenroom"; then zenroom_path="$p/zenroom"; break; fi
			done
		;;
	esac

	if test "$is_cortexm" == true; then
		for p in "${zenroom_paths[@]}"; do
			if test -r "$p/$zenroom_name"; then zenroom_path="$p/zenroom.bin"; break; fi
			if test -r "$p/zenroom"; then zenroom_path="$p/zenroom.bin"; break; fi
		done
	fi

	if ! test -r $zenroom_path; then
		echo "Zenroom executable not found"
		echo "download yours from https://files.dyne.org/zenroom/nightly/"
		exit 1
	fi
	chmod +x $zenroom_path
	>&2 echo "## ZENCODE TEST#############################################"
	>&2 echo
	>&2 echo "`basename $PWD`"
	>&2 echo
	>&2 echo "exec: $zenroom_path"
	>&2 echo
	>&2 echo "############################################################"
	>&2 echo
	echo "$zenroom_path"
	unset zenroom_paths zenroom_path
}

detect_zenroom_conf() {
	zenroom_conf=""
	if ! test "$DEBUG" == ""; then zenroom_conf="$zenroom_conf,debug=$DEBUG"; fi
	if ! test "$COLOR" == ""; then zenroom_conf="$zenroom_conf,color=$COLOR"; fi
	if test "$RNGSEED" == ""; then
		zenroom_conf="$zenroom_conf,rngseed=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
	elif test "$RNGSEED" == "random"; then
		>&2 echo "Using Real Random (no rngseed to zero)"
	elif test "$RNGSEED" == "fake"; then
		>&2 echo "Using Fake Random (deterministic incremental) TODO EXPERIMENTAL"
		# TODO
		if test "$RNGFAKE" == ""; then
			>&2 echo "ERROR: set RNGFAKE in test script to 00"
			exit 1
		fi
	else
		zenroom_conf="$zenroom_conf,rngseed=$RNGSEED"
	fi
	if ! test "$PRINT" == ""; then zenroom_conf="$zenroom_conf,print=$PRINT"; fi
	if ! test "$zenroom_conf" == ""; then
		>&2 echo "Zenroom conf: $zenroom_conf"
		echo "-c $zenroom_conf";
	fi
	unset zenroom_conf
}

qemu_zenroom_run() {
	zenroom_bin_path="src/zenroom.bin"
	if ! test -f "src/zenroom.bin"; then
		zenroom_bin_path="../../src/zenroom.bin"
	fi
	rm -rf ./outlog
	eval qemu-system-arm -M mps2-an385 -kernel $zenroom_bin_path -semihosting -nographic -semihosting-config arg="'$@'"
}

debug() {
	if [ "$Z" == "" ]; then
		>&2 echo "no zenroom executable configured"
		return 1
	fi
	if [ "$1" == "" ]; then
		>&2 echo "no script filename configured"
		return 1
	fi
	out="$1"
	shift 1
	>&2 echo "test: $out"
	tee "$out" | $Z -z $*
	return $?
}

callgrind() {
	if [ "$Z" == "" ]; then
		>&2 echo "no zenroom executable configured"
		return 1
	fi
	if [ "$1" == "" ]; then
		>&2 echo "no script filename configured"
		return 1
	fi
	out="$1"
	shift 1
	>&2 echo "test: $out"
	tee "$out" | valgrind --tool=callgrind --callgrind-out-file="${out}.callgrind" $Z -z $*
	return $?
}


incr_rngfake() {
	cat << EOF | zenroom
res = BIG.new(  )
res = res + BIG.new(1)
print(res:octet():pad(64):hex())
EOF
}

zexe() {
	if [ "$DEBUG" == "1" ]; then
		debug $*
		return $?
	fi
	if [ "$PROFILE" == "1" ]; then
		callgrind $*
		return $?
	fi
	if [ "$Z" == "" ]; then
		>&2 echo "no zenroom executable configured"
		return 1
	fi
	if [ "$1" == "" ]; then
		>&2 echo "no script filename configured"
		return 1
	fi
	out="$1"
	docs="${cookbook}/${SUBDOC}/${out}"
	mkdir -p "${cookbook}/${SUBDOC}"
	shift 1
	echo >&2
	echo "====================================" >&2
	>&2 echo "== TEST: ${SUBDOC} $out"
	t=`mktemp -d`
	# >&2 echo $t
	if [[ "$is_cortexm" == true ]]; then
		local args="$*"
		tee "$out" | qemu_zenroom_run "$args" "-z" "$out" 2>$t/stderr && cat ./outlog>$t/stdout
	else 
	        set +e
		tee "$out" | tee "$docs" | \
                MALLOC_PERTURB_=$(( $RANDOM % 255 + 1 )) \
			$Z -z $* 2>$t/stderr 1>$t/stdout
	fi
	res=$?
	set -e
	>&2 echo "exitcode: $res"
	exec_time=`grep "Time used" $t/stderr | cut -d: -f2`
	exec_memory=`grep "Memory used" $t/stderr | cut -d: -f2`
	if [[ "`uname -s`" == "Darwin" ]]; then
		out_size=`stat -f%z $t/stdout` # BSD stat
	elif [[ "`uname -s`" == "OpenBSD" ]]; then
		out_size=`stat -f%z $t/stdout` # BSD stat
	else
		out_size=`stat -c '%s' $t/stdout`
	fi
	echo "EXECUTION TIME: $exec_time" >&2
	echo "OUTPUT SIZE: $out_size" >&2
	if [ $res == 0 ]; then
		cat $t/stdout
		echo -e "OK \t|\t `basename $out` \t|\t $exec_time \t|\t $out_size \t|\t $exec_memory" \
			 >> /tmp/zenroom-test-summary.txt
	else
		>&2 cat $t/stderr | grep -v '^ \. '
		echo "ERR `basename $out`" >> /tmp/zenroom-test-summary.txt
		exit
	fi
	rm -rf "$t"
	return $res
}

save() {
	here="./"
	docs="../../docs/examples/zencode_cookbook/$1"
	mkdir -p ${docs}
	>&2 echo "output: $2"
	if [[ "${2##*.}" == "json" ]]; then
		if command -v jq > /dev/null; then
			tee ${here}/"$2" | tee ${docs}/"$2" | jq .
		fi
	else
		tee ${here}/"$2" > ${docs}/"$2"
	fi
	>&2 echo "===================================="
}

success() {
	p=`pwd`
	echo
	echo "####################################"
	echo "SUCCESS: `basename $p`"
	echo "####################################"
	echo
	echo
}

# example:
# json_extract "Alice" petition_request.json > petition_keypair.json
function json_extract {
	if ! [ -r extract.jq ]; then
		cat <<EOF > extract.jq
# break out early
def filter(\$key):
  label \$out
  | foreach inputs as \$in ( null;
      if . == null
      then if \$in[0][0] == \$key then \$in
           else empty
           end
      elif \$in[0][0] != \$key then break \$out
      else \$in
      end;
      select(length==2) );
reduce filter(\$key) as \$in ({};
  setpath(\$in[0]; \$in[1]) )
EOF
	fi
	jq -n -c --arg key "$1" --stream -f extract.jq "$2"
}

# example:
# json_remove "Alice" petition_request.json
function json_remove {
	tmp=`mktemp`
	jq -M "del(.$1)" $2 > $tmp
	mv $tmp $2
	rm -f $tmp
}

function json_join {
	jq -s 'reduce .[] as $item ({}; . * $item)' $*
}


# # requires luajit and cjson
# # example:
# # json_join left.json right.json
# function json_join {
# 	tmp=`mktemp`
# 	cat <<EOF > $tmp
# J = require "cjson"
# local fd
# fd = io.open('$1',"r")
# left = fd:read '*all'
# fd:close()
# fd = io.open('$2',"r")
# right = fd:read '*all'
# fd:close()
# local r = { }
# for k,v in pairs( J.decode( left ) ) do
# 	r[k] = v
# end
# for k,v in pairs( J.decode( right) ) do
# 	r[k] = v
# end
# print(J.encode(r))
# EOF
# 	luajit $tmp
# 	rm -f $tmp
# }
