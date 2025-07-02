// Copyright 2024 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_ZK_ZK_PROOF_H_
#define PRIVACY_PROOFS_ZK_LIB_ZK_ZK_PROOF_H_

#include <cstddef>
#include <cstdint>
#include <optional>
#include <vector>

#include "ligero/ligero_param.h"
#include "merkle/merkle_commitment.h"
#include "merkle/merkle_tree.h"
#include "sumcheck/circuit.h"
#include "util/log.h"
#include "zk/zk_common.h"

namespace proofs {

// ZkProof class handles proof serialization.
//
// We expect circuits to be created and stored locally by the prover and
// verifier respectively, and thus the circuit representations are trusted and
// are assumed to contain parameters that do not induce arithmetic overflows.
// For example, we assume that values like c.logw and c.logc are smaller than
// 2^24 and therefore do not cause any overflows (even on 32b machines) in the
// range/length calculations that are performed during serialization.
//
// An earlier experiment implemented the IO methods using protobuf parsing.
// Despite applying techniques like arena allocation, those methods required
// an order of magnitude more time.
template <class Field>
struct ZkProof {
 public:
  const Circuit<Field> &c;
  Proof<Field> proof;
  LigeroParam<Field> param;
  LigeroCommitment<Field> com;
  LigeroProof<Field> com_proof;

  // The max run length is 2^25, in order to prevent overflow issues on 32b
  // machines when performing length calculations during serialization.
  constexpr static size_t kMaxRunLen = (1 << 25);

  constexpr static size_t kMaxNumDigests = (1 << 25);

  typedef typename Field::Elt Elt;

  explicit ZkProof(const Circuit<Field> &c, size_t rate, size_t req)
      : c(c),
        proof(c.nl),
        param((c.ninputs - c.npub_in) + ZkCommon<Field>::pad_size(c), c.nl,
              rate, req),
        com_proof(&param) {}

  // Maximum size of the proof in bytes. The actual size will be smaller
  // because the Merkle proof is batched.
  size_t size() const {
    return Digest::kLength +

           proof.size() * Field::kBytes +

           com_proof.block * 2 * Field::kBytes +
           com_proof.nreq * com_proof.nrow * Field::kBytes +
           com_proof.nreq * com_proof.mc_pathlen * Digest::kLength;
  }

  void write(std::vector<uint8_t> &buf, const Field &F) const {
    size_t s0 = buf.size();
    write_com(com, buf, F);
    size_t s1 = buf.size();
    write_sc_proof(proof, buf, F);
    size_t s2 = buf.size();
    write_com_proof(com_proof, buf, F);
    size_t s3 = buf.size();
    log(INFO,
        "com:%zu, sc:%zu, com_proof:%zu [%zu el, %zu el, %zu d in %zu "
        "rows]: %zub",
        s1 - s0, s2 - s1, s3 - s2, 2 * com_proof.block,
        com_proof.nreq * com_proof.nrow, com_proof.merkle.path.size(),
        com_proof.nrow, s3);
  }

  // The read function returns false on error or underflow.
  bool read(std::vector<uint8_t>::const_iterator &buf,
            std::vector<uint8_t>::const_iterator end, const Field &F) {
    if (!read_com(com, buf, end, F)) return false;
    if (!read_sc_proof(proof, buf, end, F)) return false;
    if (!read_com_proof(com_proof, buf, end, F)) return false;
    return true;
  }

  void write_sc_proof(const Proof<Field> &pr, std::vector<uint8_t> &buf,
                      const Field &F) const {
    check(c.logc == 0, "cannot write sc proof with logc != 0");
    for (size_t i = 0; i < pr.l.size(); ++i) {
      for (size_t wi = 0; wi < c.l[i].logw; ++wi) {
        for (size_t k = 0; k < 3; ++k) {
          // Optimization: do not send p(1) as it is implied by constraints.
          if (k != 1) {
            write_elt(pr.l[i].hp[0][wi].t_[k], buf, F);
            write_elt(pr.l[i].hp[1][wi].t_[k], buf, F);
          }
        }
      }
      write_elt(pr.l[i].wc[0], buf, F);
      write_elt(pr.l[i].wc[1], buf, F);
    }
  }

  void write_com(const LigeroCommitment<Field> &com, std::vector<uint8_t> &buf,
                 const Field &F) const {
    buf.insert(buf.end(), com.root.data, com.root.data + Digest::kLength);
  }

  void write_com_proof(const LigeroProof<Field> &pr, std::vector<uint8_t> &buf,
                       const Field &F) const {
    for (size_t i = 0; i < pr.block; ++i) {
      write_elt(pr.y_ldt[i], buf, F);
    }
    for (size_t i = 0; i < pr.dblock; ++i) {
      write_elt(pr.y_dot[i], buf, F);
    }
    for (size_t i = 0; i < pr.r; ++i) {
      write_elt(pr.y_quad_0[i], buf, F);
    }
    for (size_t i = 0; i < pr.dblock - pr.block; ++i) {
      write_elt(pr.y_quad_2[i], buf, F);
    }

    // write all the Merkle nonces
    for (size_t i = 0; i < pr.nreq; ++i) {
      write_nonce(pr.merkle.nonce[i], buf);
    }

    // The format of the opened rows consists of a run of full-field elements,
    // then a run of base-field elements, and finally a run of full-field
    // elements.  To compress, we employ a run-length encoding approach.
    size_t ci = 0;
    bool subfield_run = false;
    while (ci < pr.nreq * pr.nrow) {
      size_t runlen = 0;
      while (ci + runlen < pr.nreq * pr.nrow && runlen < kMaxRunLen &&
             F.in_subfield(pr.req[ci + runlen]) == subfield_run) {
        ++runlen;
      }
      write_size(runlen, buf);
      for (size_t i = ci; i < ci + runlen; ++i) {
        if (subfield_run) {
          write_subfield_elt(pr.req[i], buf, F);
        } else {
          write_elt(pr.req[i], buf, F);
        }
      }
      ci += runlen;
      subfield_run = !subfield_run;
    }

    write_size(pr.merkle.path.size(), buf);
    for (size_t i = 0; i < pr.merkle.path.size(); ++i) {
      write_digest(pr.merkle.path[i], buf);
    }
  }

 private:
  void write_elt(const Elt &x, std::vector<uint8_t> &buf,
                 const Field &F) const {
    uint8_t tmp[Field::kBytes];
    F.to_bytes_field(tmp, x);
    buf.insert(buf.end(), tmp, tmp + Field::kBytes);
  }

  void write_subfield_elt(const Elt &x, std::vector<uint8_t> &buf,
                          const Field &F) const {
    uint8_t tmp[Field::kSubFieldBytes];
    F.to_bytes_subfield(tmp, x);
    buf.insert(buf.end(), tmp, tmp + Field::kSubFieldBytes);
  }

  void write_digest(const Digest &x, std::vector<uint8_t> &buf) const {
    buf.insert(buf.end(), x.data, x.data + Digest::kLength);
  }

  void write_nonce(const MerkleNonce &x, std::vector<uint8_t> &buf) const {
    buf.insert(buf.end(), x.bytes, x.bytes + MerkleNonce::kLength);
  }

  // Assumption is that all of the sizes of arrays that are part of proofs
  // fit into 4 bytes, and can thus work on 32-b machines.
  void write_size(size_t g, std::vector<uint8_t> &buf) const {
    for (size_t i = 0; i < 4; ++i) {
      buf.push_back(static_cast<uint8_t>(g & 0xff));
      g >>= 8;
    }
  }

  bool read_sc_proof(Proof<Field> &pr,
                     std::vector<uint8_t>::const_iterator &buf,
                     std::vector<uint8_t>::const_iterator end, const Field &F) {
    if (c.logc != 0) return false;
    for (size_t i = 0; i < pr.l.size(); ++i) {
      size_t needed = (c.l[i].logw * (3 - 1) * 2 + 2) * Field::kBytes;
      if (end - buf < needed) return false;
      for (size_t wi = 0; wi < c.l[i].logw; ++wi) {
        for (size_t k = 0; k < 3; ++k) {
          // Optimization: the p(1) value was not sent.
          if (k != 1) {
            for (size_t hi = 0; hi < 2; ++hi) {
              auto v = read_elt(buf, F);
              if (v) {
                pr.l[i].hp[hi][wi].t_[k] = v.value();
              } else {
                return false;
              }
            }
          } else {
            pr.l[i].hp[0][wi].t_[k] = F.zero();
            pr.l[i].hp[1][wi].t_[k] = F.zero();
          }
        }
      }
      for (size_t wi = 0; wi < 2; ++wi) {
        auto v = read_elt(buf, F);
        if (v) {
          pr.l[i].wc[wi] = v.value();
        } else {
          return false;
        }
      }
    }
    return true;
  }

  bool read_com(LigeroCommitment<Field> &com,
                std::vector<uint8_t>::const_iterator &buf,
                std::vector<uint8_t>::const_iterator end, const Field &F) {
    if (end - buf < Digest::kLength) return false;
    read_digest(buf, com.root);
    return true;
  }

  bool read_com_proof(LigeroProof<Field> &pr,
                      std::vector<uint8_t>::const_iterator &buf,
                      std::vector<uint8_t>::const_iterator end,
                      const Field &F) {
    if (end - buf < pr.block * Field::kBytes) return false;
    for (size_t i = 0; i < pr.block; ++i) {
      auto v = read_elt(buf, F);
      if (v) {
        pr.y_ldt[i] = v.value();
      } else {
        return false;
      }
    }

    if (end - buf < pr.dblock * Field::kBytes) return false;
    for (size_t i = 0; i < pr.dblock; ++i) {
      auto v = read_elt(buf, F);
      if (v) {
        pr.y_dot[i] = v.value();
      } else {
        return false;
      }
    }

    if (end - buf < pr.r * Field::kBytes) return false;
    for (size_t i = 0; i < pr.r; ++i) {
      auto v = read_elt(buf, F);
      if (v) {
        pr.y_quad_0[i] = v.value();
      } else {
        return false;
      }
    }

    if (end - buf < (pr.dblock - pr.block) * Field::kBytes) return false;
    for (size_t i = 0; i < pr.dblock - pr.block; ++i) {
      auto v = read_elt(buf, F);
      if (v) {
        pr.y_quad_2[i] = v.value();
      } else {
        return false;
      }
    }

    if (end - buf < pr.nreq * MerkleNonce::kLength) return false;
    for (size_t i = 0; i < pr.nreq; ++i) {
      read_nonce(buf, pr.merkle.nonce[i]);
    }

    // Decode runs of real and full Field elements.
    size_t ci = 0;
    bool subfield_run = false;
    while (ci < pr.nreq * pr.nrow) {
      if (end - buf < 4) return false;
      size_t runlen = read_size(buf); /* untrusted size input */
      if (runlen >= kMaxRunLen || ci + runlen > pr.nreq * pr.nrow) return false;
      if (subfield_run) {
        if (end - buf < runlen * Field::kSubFieldBytes) return false;
        for (size_t i = ci; i < ci + runlen; ++i) {
          auto v = read_subfield_elt(buf, F);
          if (v) {
            pr.req[i] = v.value();
          } else {
            return false;
          }
        }
      } else {
        if (end - buf < runlen * Field::kBytes) return false;
        for (size_t i = ci; i < ci + runlen; ++i) {
          auto v = read_elt(buf, F);
          if (v) {
            pr.req[i] = v.value();
          } else {
            return false;
          }
        }
      }
      ci += runlen;
      subfield_run = !subfield_run;
    }

    if (end - buf < 4) return false;
    size_t sz = read_size(buf); /* untrusted size input */

    // Merkle proofs of length < NREQ are not valid in the zk proof setting.
    if (sz < pr.nreq || sz >= kMaxNumDigests) return false;  // avoid overflow
    if (end - buf < sz * Digest::kLength) return false;

    // Sanity check, the proof should never be larger than this.
    // That value should always fit into memory, so this check aims to avoid
    // an exception by resize() if there is not enough memory to resize.
    if (sz > pr.nreq * pr.mc_pathlen) return false;

    pr.merkle.path.resize(sz);
    for (size_t i = 0; i < sz; ++i) {
      read_digest(buf, pr.merkle.path[i]);
    }
    return true;
  }

  std::optional<Elt> read_elt(std::vector<uint8_t>::const_iterator &buf,
                              const Field &F) const {
    uint8_t tmp[Field::kBytes];
    for (size_t i = 0; i < Field::kBytes; ++i) {
      tmp[i] = *buf++;
    }
    return F.of_bytes_field(tmp);
  }

  std::optional<Elt> read_subfield_elt(
      std::vector<uint8_t>::const_iterator &buf, const Field &F) const {
    uint8_t tmp[Field::kSubFieldBytes];
    for (size_t i = 0; i < Field::kSubFieldBytes; ++i) {
      tmp[i] = *buf++;
    }
    return F.of_bytes_subfield(tmp);
  }

  void read_digest(std::vector<uint8_t>::const_iterator &buf, Digest &x) const {
    for (size_t i = 0; i < Digest::kLength; ++i) {
      x.data[i] = *buf++;
    }
  }

  void read_nonce(std::vector<uint8_t>::const_iterator &buf,
                  MerkleNonce &x) const {
    for (size_t i = 0; i < MerkleNonce::kLength; ++i) {
      x.bytes[i] = *buf++;
    }
  }

  size_t read_size(std::vector<uint8_t>::const_iterator &buf) {
    size_t r = 0;
    for (size_t i = 0; i < 4; ++i) {
      r ^= *buf++ << (i * 8);
    }
    return r;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ZK_ZK_PROOF_H_
