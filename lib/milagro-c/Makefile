
CFLAGS += -std=c99 -O3 -Wall -fstack-protector
OBJS = big.o fp.o ecp.o hash.o rand.o aes.o gcm.o oct.o rom.o fp2.o ecp2.o fp4.o fp12.o pair.o rsa.o ff.o ecdh.o mpin.o wcc.o

all: ${OBJS}
	ar rcc libmilagro.a ${OBJS}

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"

clean:
	rm -f ${OBJS} libmilagro.a
