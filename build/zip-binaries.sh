#!/usr/bin/env zsh

[[ -r ../VERSION ]] || {
	print "$0: launch from build directory"
	return 1 }

VERSION=`cat ../VERSION`

if [[ "$1" == "" ]]; then
	targets=(windows apple linux javascript)
else
	targets=($*)
fi

function md2txt() {
	pandoc -f gfm -t plain -o $2 $1
}

function prepdir() {
	mkdir -p $1
	cp ../LICENSE.txt $1
	md2txt ../README.md $1/README.txt
	md2txt ../ChangeLog.md $1/ChangeLog.txt
}

function checkbin() {
	[[ -r $1 ]] && {
		cp -rv $1 $2
		chmod +x $2/$1
		return 0
	}
	print "file or dir not found: $1"
	return 1
}

function copyexamples() {
	rsync -raX ../examples $1/
}

function download() {
	# download the binaries from our jenkins SDK
	url=https://sdk.dyne.org:4443/view/zenroom/job
	latest=lastSuccessfulBuild/artifact
	build=$1
	file=$2
	rm -f `basename $file`
	if [[ "$3" == "" ]]; then
		wget $url/$build/$latest/$file
	else
		wget $url/$build/$latest/$file -O "$3"
	fi
}

for t in $targets; do
	dir=Zenroom-$VERSION-$t
	rm -rf $dir
	print "zipping $t binaries..."
	case $t in
		windows)
			prepdir $dir
			# download
			download zenroom-windows src/zenroom.dll
			download zenroom-windows src/zenroom.exe
			# pack
			checkbin zenroom.exe $dir
			checkbin zenroom.dll $dir
			copyexamples $dir
			continue ;;
		apple)
			prepdir $dir
			# download
			download zenroom-apple-ios build/zenroom-ios-arm64.a
			download zenroom-apple-ios build/zenroom-ios-armv7.a
			download zenroom-apple-ios build/zenroom-ios-x86_64.a
			download zenroom-apple-osx  src/zenroom.command
			download zenroom-python-apple-osx build/python2/_zenroom.so py2_osx_zenroom.so
			mkdir -p $dir/python2 && mv py2_osx_zenroom.so $dir/python2/_zenroom.so
			download zenroom-python-apple-osx build/python3/_zenroom.so py3_osx_zenroom.so
			mkdir -p $dir/python3 && mv py3_osx_zenroom.so $dir/python3/_zenroom.so
			# pack
			checkbin zenroom.command $dir
			checkbin zenroom-ios-arm64.a $dir
			checkbin zenroom-ios-armv7.a $dir
			checkbin zenroom-ios-x86_64.a $dir
			checkbin zenroom-wrapper.py $dir/python2
			checkbin zenroom-wrapper.py $dir/python3
			copyexamples $dir
			continue ;;
		linux)
			prepdir $dir
			# download  (TODO: destination rename)
			download zenroom-static-armhf src/zenroom-static zenroom.arm
			download zenroom-static-amd64 src/zenroom-static zenroom.x86
			download zenroom-shared-android-x86 src/zenroom.so zenroom-android-x86.so
			download zenroom-shared-android-arm src/zenroom.so zenroom-android-arm.so
			mkdir -p $dir/python2
			download zenroom-python build/python2/_zenroom.so $dir/python2/_zenroom.so
			mkdir -p $dir/python3
			# list taken from build/python3.sh - please update me!
			for v in 3.5.0 3.5.1 3.5.2 3.5.3 3.5.4 3.5.5 3.5.6 3.6.0 3.6.1 3.6.2 3.6.3 3.6.4 3.6.5 3.6.6 3.6.7 3.6.8 3.7.0 3.7.1 3.7.2; do
				download zenroom-python build/python3/_zenroom_${v}.so $dir/python3/_zenroom_${v}.so
			done
			# pack
			checkbin zenroom.x86 $dir
			checkbin zenroom.arm $dir
			checkbin zenroom-android-x86.so $dir
			checkbin zenroom-android-arm.so $dir
			# checkbin go            $dir
			checkbin zenroom-wrapper.py $dir/python2
			checkbin zenroom-wrapper.py $dir/python3
			copyexamples $dir
			continue ;;
		javascript)
			prepdir $dir
			# download
			download zenroom-react build/rnjs/zenroom.js $dir/zenroom-react.js
			mkdir -p $dir/wasm
			download zenroom-wasm build/wasm/zenroom.js     $dir/wasm/zenroom.js
			download zenroom-wasm build/wasm/zenroom.wasm   $dir/wasm/zenroom.wasm
			mkdir -p $dir/asmjs
			download zenroom-asmjs build/asmjs/zenroom.js       $dir/asmjs/zenroom.js
			download zenroom-asmjs build/asmjs/zenroom.js.mem   $dir/asmjs/zenroom.js.mem
			mkdir -p $dir/webassembly
			download zenroom-demo docs/demo/index.data   $dir/webassembly/index.data
			download zenroom-demo docs/demo/index.js     $dir/webassembly/index.js
			download zenroom-demo docs/demo/index.wasm   $dir/webassembly/index.wasm
			# pack
			checkbin zenroom_exec.js $dir
			copyexamples $dir
			continue ;;
	esac
done

for t in $targets; do
	[[ -d Zenroom-$VERSION-$t ]] || {
		print "missing archive: Zenroom-$VERSION-$t.zip"
		continue }
	rm -f Zenroom-$VERSION-$t.zip
	print  "Zenroom $VERSION by Dyne.org Foundation." |
		zip -r -9 -z \
			Zenroom-$VERSION-$t.zip Zenroom-$VERSION-$t \
			>/dev/null
	ls -lh Zenroom-$VERSION-$t.zip
done

sha256sum Zenroom-$VERSION*zip > Zenroom-$VERSION-checksums.txt

