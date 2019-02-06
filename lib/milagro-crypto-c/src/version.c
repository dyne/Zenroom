/**
 * @file version.c
 * @author Mike Scott
 * @author Kealan McCusker
 * @date 28th April 2016
 * @brief AMCL version support function
 *
 * LICENSE
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#include "version.h"

/* AMCL version support function */

/* Print version number and information about the build */
void amcl_version(void)
{
    printf("AMCL Version: %d.%d.%d\n", AMCL_VERSION_MAJOR, AMCL_VERSION_MINOR, AMCL_VERSION_PATCH);
    printf("OS: %s\n", OS);
    printf("CHUNK: %d\n", CHUNK);

    /*
     * Supported curves
     * Current choice of Elliptic Curves:
     * - NIST256
     * - C25519
     * - ED25519
     * - BRAINPOOL
     * - ANSSI
     * - NUMS256E
     * - NUMS256W
     * - NUMS384E
     * - NUMS384W
     * - NUMS512E
     * - NUMS512W
     * - HIFIVE
     * - GOLDILOCKS
     * - NIST384
     * - C41417
     * - NIST521
     * - BN254
     * - BN254CX
     * - BLS383
     */
    printf("\nSupported curves:\n");
#ifdef NIST256_VER
    printf("- NIST256\n");
#endif
#ifdef C25519_VER
    printf("- C25519\n");
#endif
#ifdef ED25519_VER
    printf("- ED25519\n");
#endif
#ifdef BRAINPOOL_VER
    printf("- BRAINPOOL\n");
#endif
#ifdef ANSSI_VER
    printf("- ANSSI\n");
#endif
#ifdef NUMS256E_VER
    printf("- NUMS256E\n");
#endif
#ifdef NUMS256W_VER
    printf("- NUMS256W\n");
#endif
#ifdef NUMS384E_VER
    printf("- NUMS384E\n");
#endif
#ifdef NUMS384W_VER
    printf("- NUMS384W\n");
#endif
#ifdef NUMS512E_VER
    printf("- NUMS512E\n");
#endif
#ifdef NUMS512W_VER
    printf("- NUMS512W\n");
#endif
#ifdef HIFIVE_VER
    printf("- HIFIVE\n");
#endif
#ifdef GOLDILOCKS_VER
    printf("- GOLDILOCKS\n");
#endif
#ifdef NIST384_VER
    printf("- NIST384\n");
#endif
#ifdef C41417_VER
    printf("- C41417\n");
#endif
#ifdef NIST521_VER
    printf("- NIST521\n");
#endif
#ifdef BN254_VER
    printf("- BN254\n");
#endif
#ifdef BN254CX_VER
    printf("- BN254CX\n");
#endif
#ifdef BLS383_VER
    printf("- BLS383\n");
#endif

    /*
     * Supported RSA security levels
     * Current choice of security levels: 2048, 3072, 4096
     */
    printf("\nRSA security levels:\n");
#ifdef RSA_SECURITY_LEVEL_2048_VER
    printf("- 2048\n");
#endif
#ifdef RSA_SECURITY_LEVEL_3072_VER
    printf("- 3072\n");
#endif
#ifdef RSA_SECURITY_LEVEL_4096_VER
    printf("- 4096\n");
#endif

}
