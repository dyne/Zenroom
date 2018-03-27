rm -f *.a
make clean
make ios-sim
make clean
make ios-armv7
make clean
make ios-arm64

make ios-fat
