CXX ?= g++
AR ?= ar
CFLAGS ?= -O2 -I../../src -I. -fstack-protector-all	\
			-D_FORTIFY_SOURCE=2 -fno-strict-overflow

include sources.mk

all: liblongfellow-zk.a

# liblongfellow-zk.a: CFLAGS += -mpclmul
liblongfellow-zk.a: ${SOURCES}
	$(AR) -r $@ ${SOURCES}

clean:
	find . -name "*.cc.o" -type f -delete
	rm -f *.a

# hard-code build information
%.cc.o: %.cc
	"$(CXX)" -std=c++17 \
	$(CFLAGS) \
	-c $< -o $@
