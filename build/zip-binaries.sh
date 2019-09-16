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
	rsync -raX ../docs/website/site $1/
	cp -v ../docs/Zencode_Whitepaper.pdf $1/
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
			# download zenroom-python-apple-osx build/python2/_zenroom.so py2_osx_zenroom.so
			# mkdir -p $dir/python2 && mv py2_osx_zenroom.so $dir/python2/_zenroom.so
			download zenroom-python-apple-osx build/zenroom-python3.tar.gz zenroom-osx-python3.tar.gz
			mkdir -p $dir && pushd $dir && tar xfz ../zenroom-osx-python3.tar.gz; popd
			# mkdir -p $dir/python3 && mv py3_osx_zenroom.so $dir/python3/_zenroom.so
			# pack
			checkbin zenroom.command $dir
			checkbin zenroom-ios-arm64.a $dir
			checkbin zenroom-ios-armv7.a $dir
			checkbin zenroom-ios-x86_64.a $dir
			# checkbin zenroom-wrapper.py $dir/python2
			checkbin zenroom-wrapper.py $dir/python3
			copyexamples $dir
			continue ;;
		linux)
			prepdir $dir
			# download  (TODO: destination rename)
			download zenroom-static-armhf src/zenroom zenroom.arm
			download zenroom-static-amd64 src/zenroom zenroom.x86
			download zenroom-shared-android-x86 src/zenroom.so zenroom-android-x86.so
			download zenroom-shared-android-arm src/zenroom.so zenroom-android-arm.so
			# mkdir -p $dir/python2
			# download zenroom-python build/python2/_zenroom.so $dir/python2/_zenroom.so
			mkdir -p $dir/python3
			download zenroom-python build/zenroom-python3.tar.gz zenroom-linux-python3.tar.gz
			mkdir -p $dir && pushd $dir && tar xfz ../zenroom-linux-python3.tar.gz; popd
			# pack
			checkbin zenroom.x86 $dir
			checkbin zenroom.arm $dir
			checkbin zenroom-android-x86.so $dir
			checkbin zenroom-android-arm.so $dir
			# checkbin go            $dir
			# checkbin zenroom-wrapper.py $dir/python2
			checkbin zenroom-wrapper.py $dir/python3
			copyexamples $dir
			continue ;;
		javascript)
			prepdir $dir
			# download
			download zenroom-react build/rnjs/zenroom.js $dir/zenroom-react.js
			mkdir -p $dir/web
			download zenroom-web build/web/zenroom.data   $dir/web/zenroom.data
			download zenroom-web build/web/zenroom.js     $dir/web/zenroom.js
			download zenroom-web build/web/zenroom.wasm   $dir/web/zenroom.wasm
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

