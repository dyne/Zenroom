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
#include "ecp_C41417.h"

/* Curve C41417 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32

const int CURVE_Cof_I_C41417= 8;
const BIG_416_29 CURVE_Cof_C41417= {0x8,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_C41417= 1;
const int CURVE_B_I_C41417= 3617;
const BIG_416_29 CURVE_B_C41417= {0xE21,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const BIG_416_29 CURVE_Order_C41417= {0x106AF79,0x18738D2F,0x18F3C606,0x1806715A,0x22B36F1,0xA67B830,0xCF32490,0x1FFFFFFD,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1FFFFFFF,0x1F};
const BIG_416_29 CURVE_Gx_C41417= {0x13CBC595,0x7E9C097,0x14DF1931,0x14E7F550,0x1A111301,0x15A6B6B5,0xD526292,0x18FEAFFE,0x1F44C03E,0x1E6A31B4,0x70C9B97,0x43180C6,0x1443300,0x19A4828A,0x68};
const BIG_416_29 CURVE_Gy_C41417= {0x22,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
#endif

#if CHUNK==64

const int CURVE_Cof_I_C41417= 8;
const BIG_416_60 CURVE_Cof_C41417= {0x8L,0x0L,0x0L,0x0L,0x0L,0x0L,0x0L};
const int CURVE_A_C41417= 1;
const int CURVE_B_I_C41417= 3617;
const BIG_416_60 CURVE_B_C41417= {0xE21L,0x0L,0x0L,0x0L,0x0L,0x0L,0x0L};
const BIG_416_60 CURVE_Order_C41417= {0xB0E71A5E106AF79L,0x1C0338AD63CF181L,0x414CF706022B36FL,0xFFFFFFFFEB3CC92L,0xFFFFFFFFFFFFFFFL,0xFFFFFFFFFFFFFFFL,0x7FFFFFFFFFFFFL};
const BIG_416_60 CURVE_Gx_C41417= {0x4FD3812F3CBC595L,0x1A73FAA8537C64CL,0x4AB4D6D6BA11130L,0x3EC7F57FF35498AL,0xE5FCD46369F44C0L,0x300218C0631C326L,0x1A334905141443L};
const BIG_416_60 CURVE_Gy_C41417= {0x22L,0x0L,0x0L,0x0L,0x0L,0x0L,0x0L};
#endif

