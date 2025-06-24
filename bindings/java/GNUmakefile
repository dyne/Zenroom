
manifest := classes/META-INF/MANIFEST.MF
VERSION := $(shell git describe --tags | cut -d- -f1)
COMMIT := $(shell git rev-parse --short HEAD)

all:
	javac -h classes dyne/zenroom/Zencode.java
	javac -d classes dyne/zenroom/Zencode.java
	mkdir -p classes/META-INF
	echo "Manifest-Version: 1.0" > ${manifest}
	echo "Created-By: Dyne.org foundation" >> ${manifest}
	echo "Implementation-Title: Zenroom" >> ${manifest}
	echo "Implementation-Version: ${VERSION}" >> ${manifest}
	echo >> ${manifest}
	jar cMf classes.jar -C classes .

test:
	javac testZenroom.java
	java -Djava.library.path=../../ testZenroom keygen.zen
