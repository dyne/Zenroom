// Copyright 2026 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_CBOR_PARSER_CBOR_BYTE_DECODER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_CBOR_PARSER_CBOR_BYTE_DECODER_H_

#include <stddef.h>
#include <stdint.h>

#include "circuits/logic/counter.h"

namespace proofs {
template <class Logic>
class CborByteDecoder {
 public:
  using CounterL = Counter<Logic>;
  using Field = typename Logic::Field;
  using EltW = typename Logic::EltW;
  using CEltW = typename CounterL::CEltW;
  using BitW = typename Logic::BitW;
  using v8 = typename Logic::v8;

  explicit CborByteDecoder(const Logic& l) : l_(l), ctr_(l) {}

  //------------------------------------------------------------
  // Decoder (lexer)
  //------------------------------------------------------------
  struct decode {
    BitW atomp;
    BitW itemsp;
    BitW stringp;
    BitW arrayp;
    BitW mapp;
    BitW tagp;
    BitW specialp;
    BitW simple_specialp;  // One of false, true, null, or undefined.
    BitW count0_23;
    BitW count24_27;
    BitW count24;
    BitW count25;
    BitW count26;
    BitW count27;
    BitW length_plus_next_v8;
    BitW count_is_next_v8;
    BitW invalid;
    CEltW length;  // of this item
    EltW as_scalar;
    CEltW as_counter;
    CEltW count_as_counter;
    v8 as_bits;
  };

  // Extract whatever we can from one v8 alone, without looking
  // at witnesses, assuming that
  // this v8 is the start of a cbor token.
  struct decode decode_one_v8(const v8& v) const {
    const Logic& L = l_;  // shorthand
    struct decode s;
    L.vassert_is_bit(v);

    // v = type:3 count:5
    auto count = L.template slice<0, 5>(v);
    auto type = L.template slice<5, 8>(v);

    s.atomp = L.veqmask(type, /*mask*/ 0b110, /*val*/ 0b000);
    s.stringp = L.veqmask(type, /*mask*/ 0b110, /*val*/ 0b010);
    s.itemsp = L.veqmask(type, /*mask*/ 0b110, /*val*/ 0b100);

    s.specialp = L.veq(type, 7);
    s.tagp = L.veq(type, 6);
    s.arrayp = L.land(s.itemsp, L.lnot(type[0]));
    s.mapp = L.land(s.itemsp, type[0]);

    // count0_23 = (0 <= count < 24) = ~(count == 11xxx)
    s.count0_23 = L.lnot(L.veqmask(count, /*mask*/ 0b11000, /*val*/ 0b11000));
    s.count24_27 = L.veqmask(count, /*mask*/ 0b11100, /*val*/ 0b11000);

    s.count24 = L.veq(count, 24);
    s.count25 = L.veq(count, 25);
    s.count26 = L.veq(count, 26);
    s.count27 = L.veq(count, 27);

    BitW count20_23 = L.veqmask(count, /*mask*/ 0b11100, /*val*/ 0b10100);
    s.simple_specialp = L.land(s.specialp, count20_23);

    // stringp && count24
    s.length_plus_next_v8 =
        L.veqmask(v, /*mask*/ 0b110'11111, /*val*/ 0b010'11000);

    // itemsp && count24
    s.count_is_next_v8 =
        L.veqmask(v, /*mask*/ 0b110'11111, /*val*/ 0b100'11000);

    BitW count0_24 = L.lor_exclusive(s.count24, s.count0_23);
    BitW atom_or_tag = L.lor_exclusive(s.atomp, s.tagp);

    // count0_24 works for all types (except invalid special)
    // but atom_or_tag supports count <= 27
    BitW good_count = L.lor(count0_24, L.land(atom_or_tag, s.count24_27));
    BitW invalid_special = L.land(s.specialp, L.lnot(s.simple_specialp));
    s.invalid = L.lor(invalid_special, L.lnot(good_count));

    s.count_as_counter = ctr_.as_counter(count);

    // Hack to compute the length.  Unclear what the right
    // abstraction should be.

    // Compute l24_27, the length assuming count24_27
    CEltW l1 = ctr_.as_counter(1 + 1);
    CEltW l2 = ctr_.as_counter(1 + 2);
    CEltW l4 = ctr_.as_counter(1 + 4);
    CEltW l8 = ctr_.as_counter(1 + 8);
    CEltW l24_25 = ctr_.mux(count[0], l2, l1);
    CEltW l26_27 = ctr_.mux(count[0], l8, l4);
    CEltW l24_27 = ctr_.mux(count[1], l26_27, l24_25);

    // choose between count0_23 and count24_27
    CEltW x1 = ctr_.as_counter(1);
    s.length = ctr_.mux(s.count0_23, x1, l24_27);

    // adjust for strings
    BitW str_23 = L.land(s.stringp, s.count0_23);
    CEltW adjust_if_string = ctr_.ite0(str_23, s.count_as_counter);
    s.length = ctr_.add(s.length, adjust_if_string);

    s.as_counter = ctr_.as_counter(v);
    s.as_scalar = L.as_scalar(v);
    s.as_bits = v;

    return s;
  }

 private:
  const Logic& l_;
  const CounterL ctr_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_CBOR_PARSER_CBOR_BYTE_DECODER_H_
