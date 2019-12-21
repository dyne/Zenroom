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
#include "fp_ANSSI.h"

/* ANNSI Curve */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 28
const BIG_256_28 Modulus_ANSSI= {0x86E9C03,0xFCF353D,0x8CA6DE8,0xADBCABC,0x35B3961,0xE8CE424,0xF10126D,0xB3AD58,0x1FD178C,0xF};
const BIG_256_28 R2modp_ANSSI= {0x288CC9C,0x18D2374,0x646BD2B,0x4929E67,0xD6F7F2D,0x220E6C1,0xABCE02E,0x751B1FD,0x7401B78,0xE};
const chunk MConst_ANSSI= 0x64E1155;
#endif

#if CHUNK==64
// Base Bits= 56
const BIG_256_56 Modulus_ANSSI= {0xFCF353D86E9C03L,0xADBCABC8CA6DE8L,0xE8CE42435B3961L,0xB3AD58F10126DL,0xF1FD178CL};
const BIG_256_56 R2modp_ANSSI= {0x18D2374288CC9CL,0x4929E67646BD2BL,0x220E6C1D6F7F2DL,0x751B1FDABCE02EL,0xE7401B78L};
const chunk MConst_ANSSI= 0x97483A164E1155L;
#endif

