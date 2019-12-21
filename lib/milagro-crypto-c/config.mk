# This file sets the default build of the library and is run by typing "make"

# size of chunk in bits which is wordlength of computer = 16, 32 or 64.  (see arch.h)
WORD_SIZE:=64

# Current choice of Elliptic Curve ANSSI C25519 NIST521 BLS24 C41417 NUMS256E BLS381 ED25519 NUMS256W BLS383 FP256BN NUMS384E BLS461 FP512BN NUMS384W BLS48 GOLDILOCKS NUMS512E BN254 HIFIVE NUMS512W BN254CX NIST256 SECP256K1 BRAINPOOL NIST384
AMCL_CURVE:=ED25519,NIST256,GOLDILOCKS,BLS381

# RSA security level: 2048 3072 4096
AMCL_RSA:=2048,4096

# Build type Debug Release Coverage ASan Check CheckFull
CMAKE_BUILD_TYPE:=Release

# Install path
CMAKE_INSTALL_PATH:=/usr/local

# Run tests
AMCL_TEST:=ON

# Build Shared Libraries ON/OFF
AMCL_BUILD_SHARED_LIBS:=ON

# Build Python wrapper ON/OFF
AMCL_BUILD_PYTHON:=ON

# Build MPIN ON/OFF
AMCL_BUILD_MPIN:=ON

# Build WCC ON/OFF
AMCL_BUILD_WCC:=ON

# Build BLS ON/OFF
AMCL_BUILD_BLS:=ON

# Build Paillier ON/OFF
AMCL_BUILD_PAILLIER:=ON

# Build Doxygen ON/OFF
AMCL_BUILD_DOCS:=ON

# Configure PIN 
AMCL_MAXPIN:=10000
AMCL_PBLEN:=14

# Print debug message for field reduction ON/OFF
DEBUG_REDUCE:=OFF

# Detect digit overflow ON/OFF
DEBUG_NORM:=OFF

# Architecture
CMAKE_C_FLAGS=

# Tool chain 
# options: ../../resources/cmake/mingw64-cross.cmake
#          ../../resources/cmake/mingw32-cross.cmake
CMAKE_TOOLCHAIN_FILE=
