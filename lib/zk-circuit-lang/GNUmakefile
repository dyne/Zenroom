# Lua bindings Makefile for Longfellow-ZK

SOURCES = lfzk_bindings.cc.o witness_bindings.cc.o
CXXFLAGS += -DSOL_NO_THREAD_LOCAL -DSOL_ALL_SAFETIES_ON

all: libzk-circuit-lang.a

libzk-circuit-lang.a: $(SOURCES)
	$(AR) -r $@ $(SOURCES)

clean:
	find . -name "*.cc.o" -type f -delete
	rm -f *.a

# hard-code build information
%.cc.o: %.cc
	$(CXX) -std=c++20 $(CXXFLAGS) -c -o $@ $<

.PHONY: all clean
