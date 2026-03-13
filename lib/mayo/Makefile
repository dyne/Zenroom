CFLAGS ?= -O2 -I../../src -I. -fPIC -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow -DMAYO_BUILD_TYPE_REF=1 -DMAYO_VARIANT=MAYO_5
CC ?= gcc

MAYO=aes_c.o aes128ctr.o fips202.o mem.o api.o mayo.o params.o arithmetic.o

all: libmayo.a

libmayo.a: ${MAYO}
	${AR} -r libmayo.a ${MAYO}

clean:
	rm -f *.a
	rm -f ${MAYO}