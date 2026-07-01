// lib/niwi/ligero/niwi_proof_serde.h
//
// Serialization and deserialization of NiwiProof wire format.
//
// The NiwiProof format carries:
//   - Magic bytes ("NIWI")
//   - Version (u16 major, u16 minor)
//   - Protocol ID (u32)
//   - Circuit digest (32 bytes)
//   - Statement digest (32 bytes)
//   - KLP22 commitment (32 bytes)
//   - KLP22 opening (64 bytes)
//   - Ligero proof body (variable-length)
//
// All field elements use the to_bytes_field / to_bytes_subfield
// conventions from Longfellow's Field type.

#ifndef NIWI_PROOF_SERDE_H
#define NIWI_PROOF_SERDE_H

#include <cstdint>
#include <cstring>
#include <vector>

#include "commitment.h"
#include "ligero/ligero_param.h"
#include "util/crypto.h"

namespace niwi {

static constexpr uint8_t kNiwiMagic[4] = {'N', 'I', 'W', 'I'};
static constexpr size_t kNiwiHeaderFixedSize = 4 + 4 + 4 + 32 + 32
    + NIWI_KLP22_COMMIT_SIZE + NIWI_KLP22_OPENING_SIZE;

/*
 * Compute the serialized size of a NiwiProof.
 *
 * Parameters after 'p' are field-specific sizes.
 */
template <class Field>
size_t niwi_proof_size(const proofs::LigeroParam<Field>& p,
                       size_t field_bytes,
                       size_t subfield_bytes) {
  size_t sz = kNiwiHeaderFixedSize;

  // Parameter block (7 x u32 = 28 bytes)
  sz += 7 * 4;

  // y_ldt: block field elements
  sz += p.block * field_bytes;

  // y_dot: dblock field elements
  sz += p.dblock * field_bytes;

  // y_quad_0: r field elements
  sz += p.r * field_bytes;

  // y_quad_2: (dblock - block) field elements
  sz += (p.dblock - p.block) * field_bytes;

  // req: nrow * nreq subfield elements
  sz += p.nrow * p.nreq * subfield_bytes;

  // merkle: nreq paths (approximate)
  sz += p.mc_pathlen / 2 * p.nreq * proofs::Digest::kLength;

  // merkle root
  sz += proofs::Digest::kLength;

  return sz;
}

/*
 * Write a u32 big-endian.
 */
inline void write_u32_be(uint8_t* buf, uint32_t val) {
  buf[0] = (uint8_t)((val >> 24) & 0xff);
  buf[1] = (uint8_t)((val >> 16) & 0xff);
  buf[2] = (uint8_t)((val >>  8) & 0xff);
  buf[3] = (uint8_t)((val      ) & 0xff);
}

/*
 * Read a u32 big-endian.
 */
inline uint32_t read_u32_be(const uint8_t* buf) {
  return ((uint32_t)buf[0] << 24) |
         ((uint32_t)buf[1] << 16) |
         ((uint32_t)buf[2] <<  8) |
         ((uint32_t)buf[3]);
}

/*
 * Write the NiwiProof header: magic, version, protocol_id,
 * circuit_digest, statement_digest, klp22_commitment, klp22_opening.
 */
inline size_t write_niwi_header(
    uint8_t* out, size_t out_cap,
    uint16_t version_major, uint16_t version_minor,
    uint32_t protocol_id,
    const uint8_t circuit_digest[32],
    const uint8_t statement_digest[32],
    const uint8_t klp22_commitment[NIWI_KLP22_COMMIT_SIZE],
    const uint8_t klp22_opening[NIWI_KLP22_OPENING_SIZE]) {

  if (out_cap < kNiwiHeaderFixedSize) return 0;

  size_t off = 0;

  // magic
  memcpy(out + off, kNiwiMagic, 4); off += 4;

  // version
  write_u32_be(out + off, ((uint32_t)version_major << 16) | version_minor);
  off += 4;

  // protocol_id
  write_u32_be(out + off, protocol_id); off += 4;

  // circuit_digest
  memcpy(out + off, circuit_digest, 32); off += 32;

  // statement_digest
  memcpy(out + off, statement_digest, 32); off += 32;

  // klp22_commitment
  memcpy(out + off, klp22_commitment, NIWI_KLP22_COMMIT_SIZE);
  off += NIWI_KLP22_COMMIT_SIZE;

  // klp22_opening
  memcpy(out + off, klp22_opening, NIWI_KLP22_OPENING_SIZE);
  off += NIWI_KLP22_OPENING_SIZE;

  return off;
}

/*
 * Read and validate the NiwiProof header.
 * Returns 0 on success, -1 on parse error.
 */
inline int read_niwi_header(
    const uint8_t* data, size_t data_len,
    uint16_t* version_major, uint16_t* version_minor,
    uint32_t* protocol_id,
    uint8_t circuit_digest[32],
    uint8_t statement_digest[32],
    uint8_t klp22_commitment[NIWI_KLP22_COMMIT_SIZE],
    uint8_t klp22_opening[NIWI_KLP22_OPENING_SIZE]) {

  if (!data || data_len < kNiwiHeaderFixedSize) return -1;

  // magic
  if (memcmp(data, kNiwiMagic, 4) != 0) return -1;
  size_t off = 4;

  // version
  uint32_t ver = read_u32_be(data + off); off += 4;
  *version_major = (uint16_t)((ver >> 16) & 0xffff);
  *version_minor = (uint16_t)(ver & 0xffff);

  // protocol_id
  *protocol_id = read_u32_be(data + off); off += 4;

  // circuit_digest
  memcpy(circuit_digest, data + off, 32); off += 32;

  // statement_digest
  memcpy(statement_digest, data + off, 32); off += 32;

  // klp22_commitment
  memcpy(klp22_commitment, data + off, NIWI_KLP22_COMMIT_SIZE);
  off += NIWI_KLP22_COMMIT_SIZE;

  // klp22_opening
  memcpy(klp22_opening, data + off, NIWI_KLP22_OPENING_SIZE);

  return 0;
}

}  // namespace niwi

#endif  // NIWI_PROOF_SERDE_H
