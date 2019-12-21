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
#include "ecp_HIFIVE.h"

/* Curve HIFIVE */


#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32

const int CURVE_Cof_I_HIFIVE= 8;
const BIG_336_29 CURVE_Cof_HIFIVE= {0x8,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_HIFIVE= 1;
const int CURVE_B_I_HIFIVE= 11111;
const BIG_336_29 CURVE_B_HIFIVE= {0x2B67,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const BIG_336_29 CURVE_Order_HIFIVE= {0x1E9FA805,0x197CACB9,0x1E4EEA9E,0x17AD70F,0x1FA9850C,0x38A0A,0x0,0x0,0x0,0x0,0x0,0x4000};
const BIG_336_29 CURVE_Gx_HIFIVE= {0xC,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const BIG_336_29 CURVE_Gy_HIFIVE= {0x5FE8632,0x15F63428,0xD976C4,0x1AACA194,0x35B6DB5,0x8E3F7A,0x52D1B0E,0xF0A7A36,0x1C161D00,0x8170C70,0x1185AD59,0x181B};
#endif

#if CHUNK==64

const int CURVE_Cof_I_HIFIVE= 8;
const BIG_336_60 CURVE_Cof_HIFIVE= {0x8L,0x0L,0x0L,0x0L,0x0L,0x0L};
const int CURVE_A_HIFIVE= 1;
const int CURVE_B_I_HIFIVE= 11111;
const BIG_336_60 CURVE_B_HIFIVE= {0x2B67L,0x0L,0x0L,0x0L,0x0L,0x0L};
const BIG_336_60 CURVE_Order_HIFIVE= {0xB2F95973E9FA805L,0xC0BD6B87F93BAA7L,0x71415FA9850L,0x0L,0x0L,0x200000000L};
const BIG_336_60 CURVE_Gx_HIFIVE= {0xCL,0x0L,0x0L,0x0L,0x0L,0x0L};
const BIG_336_60 CURVE_Gy_HIFIVE= {0x2BEC68505FE8632L,0x5D5650CA0365DB1L,0x3811C7EF435B6DBL,0x7853D1B14B46CL,0x56502E18E1C161DL,0xC0DC616BL};
#endif


