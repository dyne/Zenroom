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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_CONSTANTS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_CONSTANTS_H_

#include <stddef.h>
#include <stdint.h>

namespace proofs {

/* Max number of SHA blocks to process. */
constexpr static const size_t kMaxSHABlocks = 35;

/* Number of bits in CBOR index. Must be large enough to index into MDOC.*/
constexpr static const size_t kCborIndexBits = 12;

// This is the prefix added to the D8... mdoc encoding to produce
// a COSE1 encoding that is ready to be hashed.
static constexpr uint8_t kCose1Prefix[18] = {
    0x84, 0x6A, 0x53, 0x69, 0x67, 0x6E, 0x61, 0x74, 0x75,
    0x72, 0x65, 0x31, 0x43, 0xA1, 0x01, 0x26, 0x40, 0x59,
};
static constexpr size_t kCose1PrefixLen = 18;

/* Max size of an MSO that hashes using < MAX SHA blocks. */
constexpr static const size_t kMaxMsoLen =
    kMaxSHABlocks * 64 - 9 - kCose1PrefixLen;

static constexpr size_t kValidityInfoLen = 12;
static constexpr size_t kValidFromLen = 9;
static constexpr size_t kDeviceKeyLen = 9;
static constexpr size_t kDeviceKeyInfoLen = 13;
static constexpr size_t kValidUntilLen = 10;
static constexpr size_t kValueDigestsLen = 12;
static constexpr size_t kOrgLen = 17;

static constexpr uint8_t kTag32[] = {0x58, 0x20};
static constexpr size_t kIdLen = 32;
static constexpr size_t kValueLen = 64;

static constexpr uint8_t kValidityInfoID[kValidityInfoLen] = {
    'v', 'a', 'l', 'i', 'd', 'i', 't', 'y', 'I', 'n', 'f', 'o'};

static constexpr uint8_t kValidFromID[kValidFromLen] = {'v', 'a', 'l', 'i', 'd',
                                                        'F', 'r', 'o', 'm'};

static constexpr uint8_t kValidUntilID[kValidUntilLen] = {
    'v', 'a', 'l', 'i', 'd', 'U', 'n', 't', 'i', 'l'};

static constexpr uint8_t kDeviceKeyID[kDeviceKeyLen] = {'d', 'e', 'v', 'i', 'c',
                                                        'e', 'K', 'e', 'y'};

static constexpr uint8_t kDeviceKeyInfoID[kDeviceKeyInfoLen] = {
    'd', 'e', 'v', 'i', 'c', 'e', 'K', 'e', 'y', 'I', 'n', 'f', 'o'};

static constexpr uint8_t kValueDigestsID[kValueDigestsLen] = {
    'v', 'a', 'l', 'u', 'e', 'D', 'i', 'g', 'e', 's', 't', 's'};

static constexpr uint8_t kOrgID[kOrgLen] = {'o', 'r', 'g', '.', 'i', 's',
                                            'o', '.', '1', '8', '0', '1',
                                            '3', '.', '5', '.', '1'};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_CONSTANTS_H_
