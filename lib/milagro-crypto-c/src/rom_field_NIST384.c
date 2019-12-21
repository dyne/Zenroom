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
#include "fp_NIST384.h"

/* Curve NIST384 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 29
const BIG_384_29 Modulus_NIST384= {0x1FFFFFFF,0x7,0x0,0x1FFFFE00,0x1FFFEFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x7F};
const BIG_384_29 R2modp_NIST384= {0x0,0x8000,0x1FF80000,0x1FFFFF,0x2000000,0x0,0x0,0x1FFFFFFC,0xF,0x100,0x400,0x0,0x0,0x0};
const chunk MConst_NIST384= 0x1;
#endif

#if CHUNK==64
// Base Bits= 56
const BIG_384_56 Modulus_NIST384= {0xFFFFFFFFL,0xFFFF0000000000L,0xFFFFFFFFFEFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFL};
const BIG_384_56 R2modp_NIST384= {0xFE000000010000L,0xFFFFFFL,0x2L,0xFFFFFFFE00L,0x1000000020000L,0x0L,0x0L};
const chunk MConst_NIST384= 0x100000001L;

#endif


