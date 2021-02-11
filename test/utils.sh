# set -e
# set -o pipefail

detect_zenroom_path() {
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
	if ! test "$RNGSEED" == ""; then zenroom_conf="$zenroom_conf,rngseed=$RNGSEED"; fi
	if ! test "$SECCOMP" == ""; then zenroom_conf="$zenroom_conf,seccomp=$SECCOMP"; fi
	if ! test "$MEMWIPE" == ""; then zenroom_conf="$zenroom_conf,memwipe=$MEMWIPE"; fi
	if ! test "$zenroom_conf" == ""; then
		>&2 echo "Zenroom conf: $zenroom_conf"
		echo "-c $zenroom_conf";
	fi
	unset zenroom_conf
}

zexe() {
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
	echo >&2
	echo "====================================" >&2
	>&2 echo "test: $out"
	t=`mktemp -d`
	>&2 echo $t
	tee "$out" | $Z -z $* 2>$t/stderr 1>$t/stdout
	res=$?
	exec_time=`grep "Time used" $t/stderr | cut -d: -f2`
	out_size=`stat -c '%s' $t/stdout`
	echo "EXECUTION TIME: $exec_time" >&2
	echo "OUTPUT SIZE: `stat -c '%s' $t/stdout` bytes" >&2
	if [ $res == 0 ]; then
		cat $t/stdout
		echo -e "OK \t|\t `basename $out` \t|\t $exec_time \t|\t $out_size" >> /tmp/zenroom-test-summary.txt
	else
		>&2 cat $t/stderr | grep -v '^ \. '
		echo "ERR `basename $out`" >> /tmp/zenroom-test-summary.txt
		exit
	fi
	echo "====================================" >&2
	sleep .1 # let some air between tests
	return $res
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

# requires luajit and cjson
# example:
# json_join left.json right.json
function json_join {
	tmp=`mktemp`
	cat <<EOF > $tmp
J = require "cjson"
local fd
fd = io.open('$1',"r")
left = fd:read '*all'
fd:close()
fd = io.open('$2',"r")
right = fd:read '*all'
fd:close()
local r = { }
for k,v in pairs( J.decode( left ) ) do
	r[k] = v
end
for k,v in pairs( J.decode( right) ) do
	r[k] = v
end
print(J.encode(r))
EOF
	luajit $tmp
	rm -f $tmp
}
