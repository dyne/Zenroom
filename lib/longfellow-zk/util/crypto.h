/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025-2026 Dyne.org foundation
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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_CRYPTO_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_CRYPTO_H_

// Encapsulates all of the cryptographic primitives used by this library.
// Specifically, for the collision-resistant hash function, this library uses
// SHA256. For a pseudo-random function, this library uses AES in ECB mode.
// Finally, this library provides a method to generate random bytes using the
// openssl library.

#include <cstddef>
#include <cstdint>
#include <cstring>

#include "util/panic.h"

#include "util/sha256.h" // Replace OpenSSL includes with this
#include "util/aes_ecb.h" // Replace OpenSSL includes with this
#include <cstddef> // For size_t
#include <cstdint> // For uint8_t, uint64_t
#include <cstring> // For memcpy

namespace proofs {

	constexpr size_t kSHA256BlockSize = 64;
	constexpr size_t kSHA256DigestSize = 32;
	constexpr size_t kPRFKeySize = 32;
	constexpr size_t kPRFInputSize = 16;
	constexpr size_t kPRFOutputSize = 16;

	class SHA256 {
	public:
		SHA256() {
			state_.ctx = internal_ctx_buffer_;
			sha256_inc_init(&state_);
		}
		SHA256(const SHA256&) = delete;
		SHA256& operator=(const SHA256&) = delete;
		void Update(const uint8_t* bytes, size_t n) {
			if (finalized_) {
				ReInit();
			}
			size_t offset = 0;
			if (buffer_size_ > 0) {
				size_t needed = kSHA256BlockSize - buffer_size_;
				size_t to_copy = (n < needed) ? n : needed;
				memcpy(buffer_data_ + buffer_size_, bytes, to_copy);
				buffer_size_ += to_copy;
				offset += to_copy;
				if (buffer_size_ == kSHA256BlockSize) {
					sha256_inc_blocks(&state_, buffer_data_, 1);
					buffer_size_ = 0;
				}
			}
			size_t remaining_bytes = n - offset;
			size_t num_full_blocks = remaining_bytes / kSHA256BlockSize;
			if (num_full_blocks > 0) {
				sha256_inc_blocks(&state_, bytes + offset, num_full_blocks);
				offset += num_full_blocks * kSHA256BlockSize;
			}
			remaining_bytes = n - offset;
			if (remaining_bytes > 0) {
				memcpy(buffer_data_, bytes + offset, remaining_bytes);
				buffer_size_ = remaining_bytes;
			}
		}
		void DigestData(uint8_t digest[kSHA256DigestSize]) {
			if (finalized_) {
				ReInit();
			}
			sha256_inc_finalize(digest, &state_, buffer_data_, buffer_size_);
			buffer_size_ = 0;
			finalized_ = true;
		}
		void CopyState(const SHA256& src) {
			if (this == &src) return;
			sha256_inc_ctx_clone(&state_, &src.state_);
			if (src.buffer_size_ > 0) {
				memcpy(buffer_data_, src.buffer_data_, src.buffer_size_);
			}
			buffer_size_ = src.buffer_size_;
			finalized_ = src.finalized_;
		}
		void Update8(uint64_t x) {
			uint8_t buf[8];
			for (size_t i = 0; i < 8; ++i) {
				buf[i] = static_cast<uint8_t>(x & 0xff);
				x >>= 8;
			}
			Update(buf, 8);
		}
	private:
		void ReInit() {
			state_.ctx = internal_ctx_buffer_;
			sha256_inc_init(&state_);
			buffer_size_ = 0;
			finalized_ = false;
		}
		sha256ctx state_;
		uint8_t internal_ctx_buffer_[40];
		uint8_t buffer_data_[kSHA256BlockSize];
		size_t buffer_size_ = 0;
		bool finalized_ = false;
	};

	class PRF {
	public:
		// Constants for PRF configuration
		static constexpr size_t kPRFKeySize = 32;    // AES-256 key size (32 bytes)
		static constexpr size_t kPRFInputSize = 16;   // AES block size for input (16 bytes)
		static constexpr size_t kPRFOutputSize = 16;  // AES block size for output (16 bytes)

		// Constructor - takes 32-byte key for AES-256
		explicit PRF(const uint8_t key[kPRFKeySize]) {
			AES_init_ctx(&ctx_, key);  // Initialize with key
		}

		// Destructor - no cleanup needed for stack-allocated ctx_
		~PRF() = default;

		// Delete copy constructor and assignment operator for safety
		PRF(const PRF&) = delete;
		PRF& operator=(const PRF&) = delete;

		// Evaluates the PRF (pseudorandom function) on the input
		// This performs AES-256 encryption in ECB mode on the input block

		void Eval(uint8_t out[kPRFOutputSize], const uint8_t in[kPRFInputSize]) {
			// Copy input to output (AES_ECB_encrypt works in-place)
			memcpy(out, in, kPRFInputSize);

			// Perform AES-256 ECB encryption
			AES_ECB_encrypt(&ctx_, out);

			// Result is now in out buffer
		}
	private:
		AES_ctx ctx_;  // AES context that holds the expanded key schedule
	};

// Generate n random bytes, following the openssl API convention.
// This method will panic if the openssl library fails.
void rand_bytes(uint8_t out[/*n*/], size_t n);

void hex_to_str(char out[/* 2*n + 1*/], const uint8_t in[/*n*/], size_t n);

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_CRYPTO_H_
