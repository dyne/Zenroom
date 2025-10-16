// Copyright 2025 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_CBOR_HOST_DECODER_H_
#define PRIVACY_PROOFS_ZK_LIB_CBOR_HOST_DECODER_H_

#include <stddef.h>
#include <string.h>

#include <cstdint>
#include <vector>

#include "util/panic.h"

namespace proofs {

enum CborTag { UNSIGNED, NEGATIVE, BYTES, TEXT, ARRAY, MAP, TAG, PRIMITIVE };
enum CborPrimitive { FALSE, TRUE, CNULL };

// CBOR decoder for a subset of CBOR used in MDOC.
//
// The main advantage of this decoder is that it keeps
// offsets into the input, which is useful because we need to
// generate circuits that depend on input offsets.
//
// The other security advantage is the smaller codebase, versus
// relying on an imported CBOR parser that handles a larger subset of CBOR
// that may introduce issues.
//
// The decode function is used to process an untrusted array of bytes.
// The method returns false if the input is not processed exactly per the
// MDOC spec with only attributes in the org.iso.18013.5.1 namespace.
// The resulting CborDoc object is static, and it is assumed that neither the
// input doc, nor the tree structure changes. All of the lookup and index
// methods return const pointers to attempt to maintain this property.
class CborDoc {
 public:
  size_t header_pos_;
  enum CborTag t_;

  // A union is used to store the attributes for either singleton objects (i.e.,
  // UNSIGNED, NEGATIVE, PRIMITIVE), the start position and len of TEXT and
  // BYTES array, and the children information for ARRAY or MAP objects.
  // len of strings and byte arrays
  union U {
    uint64_t u64;         /* UNSIGNED */
    int64_t i64;          /* NEGATIVE */
    enum CborPrimitive p; /* PRIMITIVE */

    // BYTES + TEXT, represented as offset in input + length
    struct {
      size_t pos;
      size_t len;
    } string;

    // arrays, maps, and tags: an array of children nodes.
    struct {
      // The original count in the source document.  For tags,
      // the tag itself.
      size_t n;

      // The actual number of children (e.g. 2*n for maps).
      size_t nchildren;
    } items;
  } u_;

  // This field only applies to ARRAY, MAP nodes, but it has been moved
  // out of the union to avoid including components with non-default
  // constructors. It holds the children objects of an array or map. For a map,
  // even positions are the keys, and the odd positions are the values.
  std::vector<CborDoc> children_;

  // Parse a byte sequence into a CborDoc structure.
  //
  // Caller passes in the input sequence, the length of the
  // input, and pos and offset values. The offset value handles the case when
  // the input sequence is a sub-sequence of another string, as it is in
  // the MDOC and MSO parsing.
  //
  // This function can handle adversarial inputs, and returns false when the
  // input cannot be parsed.
  bool decode(const uint8_t in[], size_t len, size_t &pos, size_t offset) {
    /* invariant: pos is always compared with len before it is referenced. */
    header_pos_ = pos + offset;

    if (pos >= len) {
      return false;
    }
    uint8_t b = in[pos++];

    size_t type = (b >> 5) & 0x7u;
    size_t count0 = b & 0x1Fu;

    // variable-length count
    size_t count = 0;
    if (count0 < 24) {
      count = count0;
    } else if (count0 == 24) {
      if (pos >= len) {
        return false;
      }
      count = in[pos++];
    } else if (count0 == 25) {
      if (pos + 1 >= len) {
        return false;
      }
      count = in[pos] * 256 + in[pos + 1];
      pos += 2;
    } else if (count0 == 26) {
      if (pos + 3 >= len) {
        return false;
      }
      for (size_t i = 0; i < 4; ++i) {
        count *= 256;
        count += in[pos++];
      }
    } else {
      return false;
    }

    switch (type) { /* type \in [0,7] by construction */
      case 0:
        t_ = UNSIGNED;
        u_.u64 = count;
        break;
      case 1:
        t_ = NEGATIVE;
        u_.i64 = -(int64_t)count;
        break;

      case 2: /* BYTES */
      case 3: /* TEXT */
        if (pos + count > len) {
          return false;
        }
        t_ = (type == 2) ? BYTES : TEXT;
        u_.string.pos = pos;
        u_.string.len = count;
        pos += count;
        break;

      case 4: /* ARRAY */
        if (pos + count > len) {
          return false;
        }
        return decode_items(ARRAY, count, count, in, len, pos, offset);

      case 5: /* MAP, (key,val) pairs are stored as 2*children */
        if (pos + 2 * count > len) {
          return false;
        }
        return decode_items(MAP, 2 * count, count, in, len, pos, offset);

      case 6: /* TAG */
        // Special cases for TAG
        if (count == 1004) {  // date in the form YYYY-MM-DD
          if (pos + 1 + 10 > len) {  // 0xDA for str length + 10 characters
            return false;
          }
        }
        return decode_items(TAG, 1, count, in, len, pos, offset);

      case 7: /* PRIMITIVE */
        t_ = PRIMITIVE;
        switch (count) {
          case 20:
            u_.p = FALSE;
            break;
          case 21:
            u_.p = TRUE;
            break;
          case 22:
            u_.p = CNULL;
            break;
          default:
            return false;
        }
        break;
    }

    return true;
  }

  // Lookup a child node in an array. Returns null if the query is invalid.
  const CborDoc *index(size_t index) const {
    if (t_ == ARRAY && index < u_.items.nchildren) {
      return &children_[index];
    }
    return nullptr;
  }

  // Lookup a key in a map of type {bytes->elements}.
  // Returns null if the query is invalid.
  // The key is given as bytes with a length.
  // ndx is set to the child index of the located key.
  // The return pointer references the key, and the next object refers to
  // the value and is guaranteed to exist.
  const CborDoc *lookup(const uint8_t *const in, size_t len,
                        const uint8_t bytes[/*len*/], size_t &ndx) const {
    if (t_ == MAP) {
      for (size_t i = 0; i < u_.items.n; ++i) {
        if (children_[2 * i].eq(in, len, bytes)) {
          ndx = i;
          return &children_[2 * i];
        }
      }
    }
    return nullptr;
  }

  // Lookup a key in a map of type {unsigned->object}.
  // Returns null if the query is invalid.
  const CborDoc *lookup_unsigned(uint64_t k, size_t &ndx) const {
    if (t_ == MAP) {
      for (size_t i = 0; i < u_.items.n; ++i) {
        const CborDoc *key = &children_[2 * i];
        if (key->t_ == UNSIGNED && key->u_.u64 == k) {
          ndx = i;
          return key;
        }
      }
    }
    return nullptr;
  }

  // Lookup a key in a map of type {negative->object}.
  // Returns null if the query is invalid.
  const CborDoc *lookup_negative(int64_t k, size_t &ndx) const {
    if (t_ == MAP) {
      for (size_t i = 0; i < u_.items.n; ++i) {
        const CborDoc *key = &children_[2 * i];
        if (key->t_ == NEGATIVE && key->u_.i64 == k) {
          ndx = i;
          return key;
        }
      }
    }
    return nullptr;
  }

  // Returns the index of the item with respect to the document bytes.
  size_t position() const {
    switch (t_) {
      case UNSIGNED:
        return header_pos_;
      case BYTES:
      case TEXT:
        return u_.string.pos;
      case TAG:
        return children_[0].u_.string.pos;
      case PRIMITIVE:
        return header_pos_;
      default:
        check(false, "valueIndex called on non-value type");
    }
    return 0;
  }

  // Returns the length of the item's value in bytes.
  // According to ISO 18013-5 7.2.1, the mDL data elements shall be encoded
  // as tstr, uint, bstr, bool, or tdate, so this function only handles those
  // cases.
  size_t length() const {
    switch (t_) {
      case UNSIGNED:
        if (u_.u64 < 24) {
          return 1;
        } else if (u_.u64 < 256) {
          return 2;
        } else if (u_.u64 < 65536) {
          return 3;
        }
        return 5;
      case BYTES:
      case TEXT:
        return u_.string.len;
      case TAG:
        return children_[0].u_.string.len;  //  full-date #6.1004(tstr) format
      case PRIMITIVE:
        return 1;
      default:
        check(false, "valueLength called on non-value type");
    }
    return 0;
  }

 private:
  // Decodes a sequence of children nodes.
  bool decode_items(CborTag t, size_t nchildren, size_t items_n,
                    const uint8_t in[], size_t len, size_t &pos,
                    size_t offset) {
    t_ = t;
    u_.items.n = items_n;
    u_.items.nchildren = nchildren;
    children_.resize(nchildren);
    for (size_t i = 0; i < nchildren; ++i) {
      if (!children_[i].decode(in, len, pos, offset)) return false;
    }
    return true;
  }

  // Compares a text node to a given string of bytes.
  bool eq(const uint8_t *const in, size_t len,
          const uint8_t bytes[/*len*/]) const {
    return t_ == TEXT && u_.string.len == len &&
           memcmp(bytes, &in[u_.string.pos], len) == 0;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CBOR_HOST_DECODER_H_
