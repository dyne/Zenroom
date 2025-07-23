/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025 Dyne.org foundation
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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_PANIC_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_PANIC_H_

#include <cstdio>
#include <cstdlib>

#include "util/log.h"

extern "C" {
#include <zenroom.h>
// declares extern void *ZEN;
#include <zen_error.h>
}

namespace proofs {

inline void check(bool truth, const char* why) {
  if (!truth) {
    log(INFO, "PANIC %s", why);
	lerror(((zenroom_t*)ZEN)->lua,"%s",why);
  }
}

};  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_PANIC_H_
