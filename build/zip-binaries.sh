#!/usr/bin/env zsh

[[ -r ../VERSION ]] || {
	print "$0: launch from build directory"
	return 1 }

VERSION=`cat ../VERSION`

targets=(windows apple linux javascript)

function md2txt() {
	pandoc -f gfm -t plain -o $2 $1
}

function checkbin() {
	[[ -r $1 ]] && {
		mkdir -p $2
		cp -rv $1 $2
		chmod +x $2/$1
		cp ../LICENSE.txt $2
		md2txt ../README.md $2/README.txt
		md2txt ../ChangeLog.md $2/ChangeLog.txt
		return 0
	}
	print "file or dir not found: $1"
	return 1
}

function copyexamples() {
	rsync -raX ../examples $1/
}

for t in $targets; do
	dir=Zenroom-$VERSION-$t
	rm -rf $dir
	print "zipping $t binaries..."
	case $t in
		windows)
			checkbin zenroom.exe $dir
			checkbin zenroom.dll $dir
			copyexamples $dir
			continue ;;
		apple)
			checkbin zenroom.command $dir
			checkbin zenroom-ios.a $dir
			copyexamples $dir
			continue ;;
		linux)
			checkbin zenroom.x86 $dir
			checkbin zenroom.armhf $dir
			checkbin python2       $dir
			checkbin python3       $dir
			checkbin go            $dir
			checkbin zenroom-wrapper.py $dir/python2
			checkbin zenroom-wrapper.py $dir/python3
			checkbin libzenroomgo.so $dir
			copyexamples $dir
			continue ;;
		javascript)
			checkbin nodejs $dir
			checkbin wasm   $dir
			checkbin rnjs   $dir
			checkbin nodejs/zenroom.js.mem $dir
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

