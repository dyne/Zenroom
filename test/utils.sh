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
	>&2 echo "test: $out"
	t=`mktemp -d`
	>&2 echo $t
	tee "$out" | $Z -z $* 2>$t/stderr 1>$t/stdout
	res=$?
	if [ $res == 0 ]; then
		cat $t/stdout
		echo "OK  `basename $out`" >> /tmp/zenroom-test-summary.txt
	else
		>&2 cat $t/stderr | grep -v '^ \. '
		echo "ERR `basename $out`" >> /tmp/zenroom-test-summary.txt
		exit
	fi
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
