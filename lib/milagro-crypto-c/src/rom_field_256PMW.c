#include "arch.h"
#include "fp_256PMW.h"

/* NUMS 256-bit modulus */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 28
const BIG_256_28 Modulus_256PMW= {0xFFFFF43,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xF};
const BIG_256_28 R2modp_256PMW= {0x0,0x8900000,0x8B,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const chunk MConst_256PMW= 0xBD;
#endif

#if CHUNK==64
// Base Bits= 56
const BIG_256_56 Modulus_256PMW= {0xFFFFFFFFFFFF43L,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFL};
const BIG_256_56 R2modp_256PMW= {0x89000000000000L,0x8BL,0x0L,0x0L,0x0L};
const chunk MConst_256PMW= 0xBDL;
#endif
