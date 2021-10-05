/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2019 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#ifndef __ENCODING_H__
#define __ENCODING_H__

#include <stddef.h>

int hex2buf(char *dst, const char *hex);
void buf2hex(char *dst, const char *buf, const size_t len);

int is_url64(const char *in);

int B64decoded_len(int len);
int U64decode(char *dest, const char *src);

int B64encoded_len(int len);
void U64encode(char *dest, const char *src, int len);

int b45encode(char *dest, const char *src, int len);
int b45decode(char *dest, const char *src);
int is_base45(const char* src);

int mnemonic_from_data(char *mnemo, const char *data, int len);
int mnemonic_to_bits(const char *mnemonic, char *entropy);
int mnemonic_check_and_bits(const char *mnemonic, int* len, char *bits);
const char *const *mnemonic_wordlist(void);

#endif
