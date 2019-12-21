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
#include "fp_SECP256K1.h"

/* Curve SECP256K1 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 28
const BIG_256_28 Modulus_SECP256K1= {0xFFFFC2F,0xFFFFFEF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xF};
const BIG_256_28 R2modp_SECP256K1= {0x0,0xA100000,0x2000E90,0x7A,0x1,0x0,0x0,0x0,0x0,0x0};
const chunk MConst_SECP256K1= 0x2253531;

#endif

#if CHUNK==64

// Base Bits= 56
const BIG_256_56 Modulus_SECP256K1= {0xFFFFFEFFFFFC2FL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFL};
const BIG_256_56 R2modp_SECP256K1= {0xA1000000000000L,0x7A2000E90L,0x1L,0x0L,0x0L};
const chunk MConst_SECP256K1= 0x38091DD2253531L;

#endif

