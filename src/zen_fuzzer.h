/* This file is part of Zenroom (https://zenroom.org)
 *
 * Copyright (C) 2024 Dyne.org foundation
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

int fuzz_byte_random(lua_State *L);
int fuzz_byte_xor(lua_State *L);
int fuzz_bit_random(lua_State *L);
int fuzz_byte_circular_shift_random(lua_State *L);
int fuzz_bit_circular_shift_random(lua_State *L);
void OCT_circular_shl_bits(octet *x, int n);
