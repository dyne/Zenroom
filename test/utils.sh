set -e
set -o pipefail

detect_zenroom_path() {
	zenroom_paths=( "$PWD" "$PWD/../../src" "$PWD/../src" "$PWD/src" "/usr/local/bin" "$PWD/../.." "$PWD/.." )
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
	>&2 echo
	>&2 echo "Zenroom exec: $zenroom_path"
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
