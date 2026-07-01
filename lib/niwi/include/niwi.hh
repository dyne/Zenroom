#ifndef NIWI_HH
#define NIWI_HH

#include "niwi.h"

#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace niwi {

/* Thin C++ wrapper over the C ABI. */

/* RAII context handle. */
class Context {
public:
    explicit Context(std::span<const uint8_t> circuit_artifact)
        : ctx_(niwi_ctx_create(circuit_artifact.data(),
                                circuit_artifact.size())) {}

    ~Context() {
        if (ctx_) niwi_ctx_free(ctx_);
    }

    Context(const Context &) = delete;
    Context &operator=(const Context &) = delete;
    Context(Context &&other) noexcept : ctx_(other.ctx_) {
        other.ctx_ = nullptr;
    }
    Context &operator=(Context &&other) noexcept {
        if (this != &other) {
            if (ctx_) niwi_ctx_free(ctx_);
            ctx_ = other.ctx_;
            other.ctx_ = nullptr;
        }
        return *this;
    }

    niwi_ctx_t *get() const { return ctx_; }
    explicit operator bool() const { return ctx_ != nullptr; }

    std::string last_error() const {
        const char *msg = niwi_last_error(ctx_);
        return msg ? std::string(msg) : std::string{};
    }

private:
    niwi_ctx_t *ctx_;
};

/* Result of a prove operation. */
struct Proof {
    std::vector<uint8_t> data;
};

/* Result of an observed prove operation. */
struct ObservedProof {
    std::vector<uint8_t> proof;
    std::vector<uint8_t> gamma;
};

/* Free a buffer from the C ABI (used internally). */
inline void free_buffer(std::vector<uint8_t> &buf) {
    if (!buf.empty()) {
        niwi_free_buffer(buf.data());
        buf.clear();
    }
}

/* Prove and return the proof bytes. Throws on failure. */
inline std::vector<uint8_t> prove(niwi_ctx_t *ctx,
                                  std::span<const uint8_t> public_inputs,
                                  std::span<const uint8_t> private_inputs) {
    uint8_t *out = nullptr;
    size_t out_len = 0;
    if (niwi_prove(ctx, public_inputs.data(), public_inputs.size(),
                   private_inputs.data(), private_inputs.size(),
                   &out, &out_len) != 0) {
        throw std::runtime_error(
            std::string("niwi_prove failed: ") + niwi_last_error(ctx));
    }
    std::vector<uint8_t> result(out, out + out_len);
    niwi_free_buffer(out);
    return result;
}

/* Verify a proof. Returns true if valid. */
inline bool verify(niwi_ctx_t *ctx,
                   std::span<const uint8_t> proof,
                   std::span<const uint8_t> public_inputs) {
    return niwi_verify(ctx, proof.data(), proof.size(),
                       public_inputs.data(), public_inputs.size()) == 0;
}

} // namespace niwi

#endif /* NIWI_HH */
