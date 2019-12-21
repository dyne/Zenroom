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
#include "fp_BRAINPOOL.h"

/* Brainpool Modulus  */

#if CHUNK==16

#error Not supported

#endif

#if CHUNK==32
// Base Bits= 28
const BIG_256_28 Modulus_BRAINPOOL= {0xF6E5377,0x13481D1,0x6202820,0xF623D52,0xD726E3B,0x909D838,0xC3E660A,0xA1EEA9B,0x9FB57DB,0xA};
const BIG_256_28 R2modp_BRAINPOOL= {0xB9A3787,0x9E04F49,0x8F3CF49,0x2931721,0xF1DBC89,0x54E8C3C,0xF7559CA,0xBB411A3,0x773E15F,0x9};
const chunk MConst_BRAINPOOL= 0xEFD89B9;
#endif

#if CHUNK==64
// Base Bits= 56
const BIG_256_56 Modulus_BRAINPOOL= {0x13481D1F6E5377L,0xF623D526202820L,0x909D838D726E3BL,0xA1EEA9BC3E660AL,0xA9FB57DBL};
const BIG_256_56 R2modp_BRAINPOOL= {0x9E04F49B9A3787L,0x29317218F3CF49L,0x54E8C3CF1DBC89L,0xBB411A3F7559CAL,0x9773E15FL};
const chunk MConst_BRAINPOOL= 0xA75590CEFD89B9L;
#endif

