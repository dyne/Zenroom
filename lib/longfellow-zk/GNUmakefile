# Copyright 2025 by the Dyne.org foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CXX ?= g++
AR ?= ar

include sources.mk
SOURCES += util/aes_ecb.cc.o util/log.cc.o util/sha256.cc.o	\
						util/crypto.cc.o util/randombytes.cc.o

all: x86

x86: liblongfellow-zk.a

liblongfellow-zk.a: $(SOURCES)
	$(AR) -rcs $@ $(SOURCES)

clean:
	find . -name "*.o" -type f -delete
	rm -f *.a

# hard-code build information
%.cc.o: %.cc
	$(CXX) -std=c++17 $(CXXFLAGS) -c -o $@ $<
