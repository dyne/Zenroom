// Copyright (C) 2025-2026 Dyne.org foundation
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

#ifndef ZK_WITNESS_BINDINGS_H_
#define ZK_WITNESS_BINDINGS_H_

extern "C" {
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>
}

namespace proofs {
namespace lua {

// SHA-256 witness generation
// Args: message (OCTET), max_blocks (integer)
// Returns: table with num_blocks, padded_input (OCTET), witnesses (array of tables)
int sha256_compute_message(lua_State* L);

// ECDSA witness generation
// Args: pkX, pkY, e, r, s (all OCTETs, 32 bytes each)
// Returns: boolean success, then witness object if success
int ecdsa_create_witness(lua_State* L);

// ECDSA witness accessors (require witness object on stack)
int ecdsa_get_rx(lua_State* L);
int ecdsa_get_ry(lua_State* L);
int ecdsa_get_rx_inv(lua_State* L);
int ecdsa_get_s_inv(lua_State* L);

// Type conversion utilities
// Args: bytes (OCTET, 32 bytes)
// Returns: table representing Nat (for debugging/inspection)
int nat_from_octet_be(lua_State* L);

// Module registration
int luaopen_zk_witness(lua_State* L);

}  // namespace lua
}  // namespace proofs

#endif  // ZK_WITNESS_BINDINGS_H_
