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
#include "ecp_C25519.h"

/* Curve 25519 */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
const int CURVE_Cof_I_C25519=8;
const BIG_256_29 CURVE_Cof_C25519= {0x8,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
const int CURVE_A_C25519=486662;
const BIG_256_29 CURVE_Order_C25519= {0x1CF5D3ED,0x9318D2,0x1DE73596,0x1DF3BD45,0x14D,0x0,0x0,0x0,0x100000};
const BIG_256_29 CURVE_Gx_C25519= {0x9};
#endif

#if CHUNK==64
const int CURVE_Cof_I_C25519=8;
const BIG_256_56 CURVE_Cof_C25519= {0x8,0x0,0x0,0x0,0x0};
const int CURVE_A_C25519=486662;
const BIG_256_56 CURVE_Order_C25519= {0x12631A5CF5D3ED,0xF9DEA2F79CD658,0x14DE,0x0,0x10000000};
const BIG_256_56 CURVE_Gx_C25519= {0x9};
#endif

