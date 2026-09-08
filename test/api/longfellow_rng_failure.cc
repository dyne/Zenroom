#include <cstdint>
#include <cstring>
#include <vector>

#include <longfellow-zk/circuits/mdoc/mdoc_rng_adapter.h>

struct DeterministicRng {
  uint32_t state;
  size_t calls;
};

static int deterministic_rng(void* context, void* output, size_t length) {
  auto* rng = static_cast<DeterministicRng*>(context);
  auto* out = static_cast<uint8_t*>(output);
  ++rng->calls;
  for (size_t i = 0; i < length; ++i) {
    rng->state = rng->state * 1664525u + 1013904223u;
    out[i] = static_cast<uint8_t>(rng->state >> 24);
  }
  return 0;
}

static int failing_rng(void* context, void* output, size_t length) {
  ++*static_cast<size_t*>(context);
  std::memset(output, 0xa5, length);
  return -1;
}

static std::vector<uint8_t> sample(proofs::CallbackRandomEngine& engine) {
  std::vector<uint8_t> bytes(96);
  engine.bytes(bytes.data(), bytes.size());
  return bytes;
}

int main() {
  DeterministicRng first{1, 0}, same{1, 0}, different{2, 0};
  proofs::CallbackRandomEngine first_engine(deterministic_rng, &first);
  proofs::CallbackRandomEngine same_engine(deterministic_rng, &same);
  proofs::CallbackRandomEngine different_engine(deterministic_rng, &different);
  const std::vector<uint8_t> first_bytes = sample(first_engine);
  const std::vector<uint8_t> same_bytes = sample(same_engine);
  const std::vector<uint8_t> different_bytes = sample(different_engine);

  size_t failures = 0;
  proofs::CallbackRandomEngine failed_engine(failing_rng, &failures);
  const std::vector<uint8_t> failed_bytes = sample(failed_engine);
  proofs::CallbackRandomEngine null_engine(nullptr, nullptr);
  const std::vector<uint8_t> null_bytes = sample(null_engine);
  const std::vector<uint8_t> zeroes(96, 0);

  return first.calls == 1 && same.calls == 1 && different.calls == 1 &&
                 first_bytes == same_bytes && first_bytes != different_bytes &&
                 !first_engine.failed() && !same_engine.failed() &&
                 !different_engine.failed() && failures == 1 &&
                 failed_engine.failed() && failed_bytes == zeroes &&
                 null_engine.failed() && null_bytes == zeroes
             ? 0
             : 1;
}
