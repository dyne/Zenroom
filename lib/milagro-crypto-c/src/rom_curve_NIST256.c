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
#include "ecp_NIST256.h"

/* Curve NIST256 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32

const int CURVE_Cof_I_NIST256= 1;
const BIG_256_28 CURVE_Cof_NIST256= {0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_NIST256= -3;
const int CURVE_B_I_NIST256= 0;
const BIG_256_28 CURVE_B_NIST256= {0x7D2604B,0xCE3C3E2,0x3B0F63B,0x6B0CC5,0x6BC651D,0x5576988,0x7B3EBBD,0xAA3A93E,0xAC635D8,0x5};
const BIG_256_28 CURVE_Order_NIST256= {0xC632551,0xB9CAC2F,0x79E84F3,0xFAADA71,0xFFFBCE6,0xFFFFFFF,0xFFFFFF,0x0,0xFFFFFFF,0xF};
const BIG_256_28 CURVE_Gx_NIST256= {0x898C296,0xA13945D,0xB33A0F4,0x7D812DE,0xF27703,0xE563A44,0x7F8BCE6,0xE12C424,0xB17D1F2,0x6};
const BIG_256_28 CURVE_Gy_NIST256= {0x7BF51F5,0xB640683,0x15ECECB,0x33576B3,0xE162BCE,0x4A7C0F9,0xB8EE7EB,0xFE1A7F9,0xFE342E2,0x4};


#endif

#if CHUNK==64

const int CURVE_Cof_I_NIST256= 1;
const BIG_256_56 CURVE_Cof_NIST256= {0x1L,0x0L,0x0L,0x0L,0x0L};
const int CURVE_A_NIST256= -3;
const int CURVE_B_I_NIST256= 0;
const BIG_256_56 CURVE_B_NIST256= {0xCE3C3E27D2604BL,0x6B0CC53B0F63BL,0x55769886BC651DL,0xAA3A93E7B3EBBDL,0x5AC635D8L};
const BIG_256_56 CURVE_Order_NIST256= {0xB9CAC2FC632551L,0xFAADA7179E84F3L,0xFFFFFFFFFFBCE6L,0xFFFFFFL,0xFFFFFFFFL};
const BIG_256_56 CURVE_Gx_NIST256= {0xA13945D898C296L,0x7D812DEB33A0F4L,0xE563A440F27703L,0xE12C4247F8BCE6L,0x6B17D1F2L};
const BIG_256_56 CURVE_Gy_NIST256= {0xB6406837BF51F5L,0x33576B315ECECBL,0x4A7C0F9E162BCEL,0xFE1A7F9B8EE7EBL,0x4FE342E2L};
#endif

