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
#include "ecp_NUMS256W.h"

/*  NUMS 256-bit Curve - Weierstrass */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
const int CURVE_Cof_I_NUMS256W= 1;
const BIG_256_28 CURVE_Cof_NUMS256W= {0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_NUMS256W= -3;
const int CURVE_B_I_NUMS256W= 152961;
const BIG_256_28 CURVE_B_NUMS256W= {0x25581,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const BIG_256_28 CURVE_Order_NUMS256W= {0x751A825,0xAB20294,0x65C6020,0x8275EA2,0xFFFE43C,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xF};
const BIG_256_28 CURVE_Gx_NUMS256W= {0x21AACB1,0x52EE1EB,0x4C73ABC,0x9B0903D,0xB098357,0xA04F42C,0x1297A95,0x5AAADB6,0xC9ED6B6,0xB};
const BIG_256_28 CURVE_Gy_NUMS256W= {0x184DE9F,0xB5B9CB2,0x10FBB80,0xC3D1153,0x35C955,0xF77E04E,0x673448B,0x3399B6A,0x8FC0F1,0xD};

#endif

#if CHUNK==64
const int CURVE_Cof_I_NUMS256W= 1;
const BIG_256_56 CURVE_Cof_NUMS256W= {0x1L,0x0L,0x0L,0x0L,0x0L};
const int CURVE_A_NUMS256W= -3;
const int CURVE_B_I_NUMS256W= 152961;
const BIG_256_56 CURVE_B_NUMS256W= {0x25581L,0x0L,0x0L,0x0L,0x0L};
const BIG_256_56 CURVE_Order_NUMS256W= {0xAB20294751A825L,0x8275EA265C6020L,0xFFFFFFFFFFE43CL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFL};
const BIG_256_56 CURVE_Gx_NUMS256W= {0x52EE1EB21AACB1L,0x9B0903D4C73ABCL,0xA04F42CB098357L,0x5AAADB61297A95L,0xBC9ED6B6L};
const BIG_256_56 CURVE_Gy_NUMS256W= {0xB5B9CB2184DE9FL,0xC3D115310FBB80L,0xF77E04E035C955L,0x3399B6A673448BL,0xD08FC0F1L};

#endif
