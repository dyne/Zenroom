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
#include "fp_NIST256.h"

/* Curve NIST256 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 28
const BIG_256_28 Modulus_NIST256= {0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFF,0x0,0x0,0x1000000,0x0,0xFFFFFFF,0xF};
const BIG_256_28 R2modp_NIST256= {0x50000,0x300000,0x0,0x0,0xFFFFFFA,0xFFFFFBF,0xFFFFEFF,0xFFFAFFF,0x2FFFF,0x0};
const chunk MConst_NIST256= 0x1;
#endif

#if CHUNK==64

// Base Bits= 56
const BIG_256_56 Modulus_NIST256= {0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFL,0x0L,0x1000000L,0xFFFFFFFFL};
const BIG_256_56 R2modp_NIST256= {0x3000000050000L,0x0L,0xFFFFFBFFFFFFFAL,0xFFFAFFFFFFFEFFL,0x2FFFFL};
const chunk MConst_NIST256= 0x1L;

#endif

