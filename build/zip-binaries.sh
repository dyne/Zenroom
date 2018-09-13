#!/usr/bin/env zsh

[[ -r ../VERSION ]] || {
	print "$0: launch from build directory"
	return 1 }

VERSION=`cat ../VERSION`

targets=(windows apple linux javascript)

function checkbin() {
	[[ -r $1 ]] && {
		mkdir -p $2
		cp -v $1 $2
		chmod +x $2/$1
		cp ../LICENSE.txt $2
		cp ../README.md $2
		cp ../ChangeLog.md $2
		return 0
	}
	print "file not found: $1"
	return 1
}

function checkdir() {
	[[ -d $1 ]] && {
		mkdir -p $2/$1
		cp -v $1/* $2/$1/
		cp ../LICENSE.txt $2
		cp ../README.md $2
		cp ../ChangeLog.md $2
		rsync -raX ../examples $2/
		return 0
	}
	print "directory not found: $1"
	return 1
}

for t in $targets; do
	dir=Zenroom-$VERSION-$t
	rm -rf $dir
	print "zipping $t binaries..."
	case $t in
		windows)
			checkbin zenroom.exe $dir
			checkbin zenroom.dll $dir
			continue ;;
		apple)
			checkbin zenroom.command $dir
			checkbin zenroom-ios.a $dir
			continue ;;
		linux)
			checkbin zenroom.x86 $dir
			checkbin zenroom.armhf $dir
			checkbin _zenroom.so   $dir
			checkbin zenroom-wrapper.py $dir
			checkbin libzenroomgo.so $dir
			continue ;;
		javascript)
			checkdir nodejs $dir
			checkdir wasm   $dir
			checkbin nodejs/zenroom.js.mem $dir
			checkbin zenroom_exec.js $dir
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

