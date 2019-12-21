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
#include "fp_BLS381.h"

/* Curve BLS381 - Pairing friendly BLS curve */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 29
const BIG_384_29 Modulus_BLS381= {0x1FFFAAAB,0xFF7FFFF,0x14FFFFEE,0x17FFFD62,0xF6241EA,0x9507B58,0xAFD9CC3,0x109E70A2,0x1764774B,0x121A5D66,0x12C6E9ED,0x12FFCD34,0x111EA3,0xD};
const BIG_384_29 R2modp_BLS381= {0x15BEF7AE,0x1031CD0E,0x2DD93E8,0x9226323,0xE6E2CD2,0x11684DAA,0x1170E5DB,0x88E25B1,0x1B366399,0x1C536F47,0xD1F9CBC,0x278B67F,0x1EA66A2B,0xC};
const chunk MConst_BLS381= 0x1FFCFFFD;
const BIG_384_29 Fra_BLS381= {0x12235FB8,0x83BAF6C,0x19E04F63,0x1D4A7AC7,0xB9C4F67,0x1EBC25D,0x1D3DEC91,0x1FA797AB,0x1F0FD603,0x1016068,0x108C6FAD,0x5760CCF,0x104D3BF0,0xC};
const BIG_384_29 Frb_BLS381= {0xDDC4AF3,0x7BC5093,0x1B1FB08B,0x1AB5829A,0x3C5F282,0x764B8FB,0xDBFB032,0x10F6D8F6,0x1854A147,0x1118FCFD,0x23A7A40,0xD89C065,0xFC3E2B3,0x0};

#endif

#if CHUNK==64
// Base Bits= 58
const BIG_384_58 Modulus_BLS381= {0x1FEFFFFFFFFAAABL,0x2FFFFAC54FFFFEEL,0x12A0F6B0F6241EAL,0x213CE144AFD9CC3L,0x2434BACD764774BL,0x25FF9A692C6E9EDL,0x1A0111EA3L};
const BIG_384_58 R2modp_BLS381= {0x20639A1D5BEF7AEL,0x1244C6462DD93E8L,0x22D09B54E6E2CD2L,0x111C4B63170E5DBL,0x38A6DE8FB366399L,0x4F16CFED1F9CBCL,0x19EA66A2BL};
const chunk MConst_BLS381= 0x1F3FFFCFFFCFFFDL;
const BIG_384_58 Fra_BLS381= {0x10775ED92235FB8L,0x3A94F58F9E04F63L,0x3D784BAB9C4F67L,0x3F4F2F57D3DEC91L,0x202C0D1F0FD603L,0xAEC199F08C6FADL,0x1904D3BF0L};
const BIG_384_58 Frb_BLS381= {0xF78A126DDC4AF3L,0x356B0535B1FB08BL,0xEC971F63C5F282L,0x21EDB1ECDBFB032L,0x2231F9FB854A147L,0x1B1380CA23A7A40L,0xFC3E2B3L};

#endif
