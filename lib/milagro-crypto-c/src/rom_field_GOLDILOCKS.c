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
#include "fp_GOLDILOCKS.h"

/* Curve GOLDILOCKS */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32

// Base Bits= 29
const BIG_448_29 Modulus_GOLDILOCKS= {0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FDFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFF};
const BIG_448_29 R2modp_GOLDILOCKS= {0x0,0x10,0x0,0x0,0x0,0x0,0x0,0x0,0x3000000,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const chunk MConst_GOLDILOCKS= 0x1;

#endif

#if CHUNK==64
// Base Bits= 58
const BIG_448_58 Modulus_GOLDILOCKS= {0x3FFFFFFFFFFFFFFL,0x3FFFFFFFFFFFFFFL,0x3FFFFFFFFFFFFFFL,0x3FBFFFFFFFFFFFFL,0x3FFFFFFFFFFFFFFL,0x3FFFFFFFFFFFFFFL,0x3FFFFFFFFFFFFFFL,0x3FFFFFFFFFFL};
const BIG_448_58 R2modp_GOLDILOCKS= {0x200000000L,0x0L,0x0L,0x0L,0x3000000L,0x0L,0x0L,0x0L};
const chunk MConst_GOLDILOCKS= 0x1L;


#endif


