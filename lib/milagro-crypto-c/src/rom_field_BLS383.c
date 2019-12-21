/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*/

#include "arch.h"
#include "fp_BLS383.h"

/* Curve BLS383 - Pairing friendly BLS curve */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 29
const BIG_384_29 Modulus_BLS383= {0x5AAB0AB,0x11B8EB24,0x19214AF6,0x187E5314,0x124F47A8,0x1C00B4B0,0x1446B0C6,0x59E6CB4,0x4A0AD46,0xFF5494,0x81B6B71,0x956DD6B,0x16556956,0x2A};
const BIG_384_29 R2modp_BLS383= {0x116907F4,0x405B700,0x1752AC11,0x67A9E7C,0x1941C581,0x1AEA38C4,0xB1E4D22,0xCE841AE,0xA0FC49B,0xB4B1F48,0x13852312,0x1B3FDCED,0x1FECE397,0x26};
const chunk MConst_BLS383= 0x73435FD;
const BIG_384_29 Fra_BLS383= {0x1311DAC1,0x296B969,0x19DCF806,0x126901FC,0xD8C8A36,0x1A2572A8,0xA1A0959,0x1A47F743,0x110E4C6C,0x1608DA97,0xCE2E7F0,0x4FED178,0xACD5BF0,0x11};
const BIG_384_29 Frb_BLS383= {0x1298D5EA,0xF2231BA,0x1F4452F0,0x6155117,0x4C2BD72,0x1DB4208,0xA2CA76D,0xB567571,0x139260D9,0xAF679FC,0x1B388380,0x4580BF2,0xB880D66,0x19};

#endif

#if CHUNK==64
// Base Bits= 58
const BIG_384_58 Modulus_BLS383= {0x2371D6485AAB0ABL,0x30FCA6299214AF6L,0x3801696124F47A8L,0xB3CD969446B0C6L,0x1FEA9284A0AD46L,0x12ADBAD681B6B71L,0x556556956L};
const BIG_384_58 R2modp_BLS383= {0x80B6E0116907F4L,0xCF53CF9752AC11L,0x35D47189941C581L,0x19D0835CB1E4D22L,0x16963E90A0FC49BL,0x367FB9DB3852312L,0x4DFECE397L};
const chunk MConst_BLS383= 0x1BC0571073435FDL;
const BIG_384_58 Fra_BLS383= {0x52D72D3311DAC1L,0x24D203F99DCF806L,0x344AE550D8C8A36L,0x348FEE86A1A0959L,0x2C11B52F10E4C6CL,0x9FDA2F0CE2E7F0L,0x22ACD5BF0L};
const BIG_384_58 Frb_BLS383= {0x1E446375298D5EAL,0xC2AA22FF4452F0L,0x3B684104C2BD72L,0x16ACEAE2A2CA76DL,0x15ECF3F939260D9L,0x8B017E5B388380L,0x32B880D66L};

#endif
