AMCL is very simple to build.

The examples here are for GCC under Linux and Windows (using MINGW).

First - decide what you want to do. Edit amcl_.h - note there is only
one area where USER CONFIGURABLE input is requested.

Here set the wordlength of your computer, and choose your curve.

Once this is done, build the library, and compile and link your program 
with an API file and the ROM file rom.c that contains curve constants.

Three example API files are provided, mpin.c which supports our M-Pin 
(tm) protocol, ecdh.c which supports standard elliptic 
curve key exchange, digital signature and public key crypto, and rsa.c 
which supports the RSA method. The first 
can be tested using the testmpin.c driver programs, the second can 
be tested using testecm/testecdh.c, and the third can be tested using
testrsa.c

In the ROM file you must provide the curve constants. Several examples
are provided there, and if you are willing to use one of these, simply
select your curve of CHOICE in amcl_.h

Example (1), in amcl_.h choose

#define CHOICE BN

Under windows run the batch file build_pair.bat to build the amcl.a library
and the testmpin.exe applications.

For linux execute "bash build_pair"

Example (2), in amcl_.h choose

#define CHOICE C25519

to select the Edwards curve ed25519.

Under Windows run the batch file build_ec.bat to build the amcl.a library and
the testecdh.exe application.

For Linux execute "bash build_ec"


To help generate the ROM constants for your own curve some MIRACL helper 
programs are included. The program bngen.cpp generates a ROM file for a 
BN curve, and the program ecgen.cpp generates the ROM for EC curves. 

The program bigtobig.cpp converts a big number to the AMCL 
BIG format.


For quick jumpstart:-

(Linux)
bash build_pair
./testmpin

(Windows + MingW)
build_pair
testmpin
