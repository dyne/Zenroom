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
#include "ecp_ANSSI.h"

/* ANSSI Curve */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
const int CURVE_Cof_I_ANSSI= 1;
const BIG_256_28 CURVE_Cof_ANSSI= {0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_ANSSI= -3;
const int CURVE_B_I_ANSSI= 0;
const BIG_256_28 CURVE_B_ANSSI= {0xB7BB73F,0x75ED967,0x1A18030,0xC9AE4B,0xFDFEC,0x754A44C,0xD4ABA,0x5428A93,0xE353FCA,0xE};
const BIG_256_28 CURVE_Order_ANSSI= {0x6D655E1,0xFDD459C,0x2BF941F,0x67E140D,0x35B53DC,0xE8CE424,0xF10126D,0xB3AD58,0x1FD178C,0xF};
const BIG_256_28 CURVE_Gx_ANSSI= {0x98F5CFF,0xC97A2DD,0x8B70164,0xD2DCAF9,0x3958C27,0x4749D42,0xB31183D,0x56C139E,0x6B3D4C3,0xB};
const BIG_256_28 CURVE_Gy_ANSSI= {0x4062CFB,0x115A155,0x4C9E183,0xC307E8E,0xF8C2701,0xF0F3ECE,0x11F9271,0xC8B2049,0x142E0F7,0x6};
#endif

#if CHUNK==64
const int CURVE_Cof_I_ANSSI= 1;
const BIG_256_56 CURVE_Cof_ANSSI= {0x1L,0x0L,0x0L,0x0L,0x0L};
const int CURVE_A_ANSSI= -3;
const int CURVE_B_I_ANSSI= 0;
const BIG_256_56 CURVE_B_ANSSI= {0x75ED967B7BB73FL,0xC9AE4B1A18030L,0x754A44C00FDFECL,0x5428A9300D4ABAL,0xEE353FCAL};
const BIG_256_56 CURVE_Order_ANSSI= {0xFDD459C6D655E1L,0x67E140D2BF941FL,0xE8CE42435B53DCL,0xB3AD58F10126DL,0xF1FD178CL};
const BIG_256_56 CURVE_Gx_ANSSI= {0xC97A2DD98F5CFFL,0xD2DCAF98B70164L,0x4749D423958C27L,0x56C139EB31183DL,0xB6B3D4C3L};
const BIG_256_56 CURVE_Gy_ANSSI= {0x115A1554062CFBL,0xC307E8E4C9E183L,0xF0F3ECEF8C2701L,0xC8B204911F9271L,0x6142E0F7L};
#endif

