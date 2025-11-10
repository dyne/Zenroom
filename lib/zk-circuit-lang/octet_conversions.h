// Copyright (C) 2025 Dyne.org foundation
// designed, written and maintained by Denis Roio <jaromil@dyne.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef ZK_OCTET_CONVERSIONS_H_
#define ZK_OCTET_CONVERSIONS_H_

extern "C" {
#include <lua.h>
	struct octet;
	const char *o_val(const octet*);
	size_t o_len(const octet*);
	octet* o_new(lua_State*, const int);
	octet* o_dup(lua_State*, const octet*);
	const octet* o_arg(lua_State*, int);
	octet* o_push(lua_State*, const char*, size_t);
	void o_free(lua_State*, const octet*);
}

#include "ec/p256.h"
#include "algebra/fp_p256.h"

namespace proofs {
namespace lua {

// Convert OCTET to Nat (big-endian, expects 32 bytes)
template <class Nat>
Nat nat_from_octet(const octet* oct) {
	size_t oct_len = o_len(oct);
    if (oct_len != Nat::kBytes) return Nat(0);

	const char *oct_val = o_val(oct);
    uint8_t tmp[Nat::kBytes];
    // Transform from big-endian to little-endian
    for (size_t i = 0; i < Nat::kBytes; ++i) {
        tmp[i] = oct_val[Nat::kBytes - i - 1];
    }
    return Nat::of_bytes(tmp);
}

// Convert Nat to OCTET (big-endian, creates new OCTET on Lua stack)
template <class Nat>
void nat_to_octet(lua_State* L, const Nat& n) {
    uint8_t bytes[Nat::kBytes];
    
    // Get little-endian bytes from Nat
    uint8_t le_bytes[Nat::kBytes];
    n.to_bytes(le_bytes);
    
    // Convert to big-endian
    for (size_t i = 0; i < Nat::kBytes; ++i) {
        bytes[i] = le_bytes[Nat::kBytes - 1 - i];
    }
    
    // Push as OCTET
    extern octet* o_push(lua_State*, const char*, size_t);
    ::o_push(L, (char*)bytes, Nat::kBytes);
}

// Convert field element to OCTET (from Montgomery form)
template <class Field>
void field_elt_to_octet(lua_State* L, const typename Field::Elt& elt, const Field& field) {
    auto nat = field.from_montgomery(elt);
    nat_to_octet(L, nat);
}

}  // namespace lua
}  // namespace proofs

#endif  // ZK_OCTET_CONVERSIONS_H_
