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

/**
 * @file utils.h
 * @author Kealan McCusker
 * @brief Utility functions Header File
 *
 */

/* AMCL Support functions for M-Pin servers */

#ifndef UTILS_H
#define UTILS_H

#include "amcl.h"

/**
 * @brief Decode hex value
 *
 * Decode hex value.
 *
 * @param src     Hex encoded string
 * @param dst     Binary string
 * @param src_len length Hex encoded string
 */
void amcl_hex2bin(const char *src, char *dst, int src_len);

/**
 * @brief Encode binary string
 *
 * Encode binary string.
 *
 * @param src     Binary string
 * @param dst     Hex encoded string
 * @param src_len length binary string
 */
void amcl_bin2hex(char *src, char *dst, int src_len);

/**
 * @brief Print encoded binary string in hex
 *
 * Print encoded binary string in hex.
 *
 * @param src     Binary string
 * @param src_len length binary string
 */
void amcl_print_hex(char *src, int src_len);

/**
 * @brief Generate a random Octet
 *
 * Generate a random Octet.
 *
 * @param  RNG             random number generator
 * @param  randomValue     random Octet
 */
void generateRandom(csprng* RNG, octet* randomValue);

/**
 * @brief Generate a random six digit one time password
 *
 * Generates a random six digit one time password.
 *
 * @param  RNG             random number generator
 * @return OTP             One Time Password
 */
int generateOTP(csprng* RNG);

#endif
