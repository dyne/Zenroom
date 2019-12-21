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
#include "ecp_SECP256K1.h"

/* Curve SECP256K1 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32

const int CURVE_Cof_I_SECP256K1= 1;
const BIG_256_28 CURVE_Cof_SECP256K1= {0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_SECP256K1= 0;
const int CURVE_B_I_SECP256K1= 7;
const BIG_256_28 CURVE_B_SECP256K1= {0x7,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const BIG_256_28 CURVE_Order_SECP256K1= {0x364141,0xD25E8CD,0x8A03BBF,0xDCE6AF4,0xFFEBAAE,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xF};
const BIG_256_28 CURVE_Gx_SECP256K1= {0x6F81798,0xF2815B1,0xE28D959,0xFCDB2DC,0xB07029B,0x95CE870,0xC55A062,0xF9DCBBA,0x9BE667E,0x7};
const BIG_256_28 CURVE_Gy_SECP256K1= {0xB10D4B8,0x47D08FF,0x554199C,0xB448A68,0x8A8FD17,0xFC0E110,0x55DA4FB,0x26A3C46,0x83ADA77,0x4};



#endif

#if CHUNK==64

const int CURVE_Cof_I_SECP256K1= 1;
const BIG_256_56 CURVE_Cof_SECP256K1= {0x1L,0x0L,0x0L,0x0L,0x0L};
const int CURVE_A_SECP256K1= 0;
const int CURVE_B_I_SECP256K1= 7;
const BIG_256_56 CURVE_B_SECP256K1= {0x7L,0x0L,0x0L,0x0L,0x0L};
const BIG_256_56 CURVE_Order_SECP256K1= {0xD25E8CD0364141L,0xDCE6AF48A03BBFL,0xFFFFFFFFFEBAAEL,0xFFFFFFFFFFFFFFL,0xFFFFFFFFL};
const BIG_256_56 CURVE_Gx_SECP256K1= {0xF2815B16F81798L,0xFCDB2DCE28D959L,0x95CE870B07029BL,0xF9DCBBAC55A062L,0x79BE667EL};
const BIG_256_56 CURVE_Gy_SECP256K1= {0x47D08FFB10D4B8L,0xB448A68554199CL,0xFC0E1108A8FD17L,0x26A3C4655DA4FBL,0x483ADA77L};

#endif

