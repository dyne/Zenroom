milagro := ../../lib/milagro-c
CFLAGS := -I${milagro} -std=c99 -fstack-protector -ggdb
LDADD := -L${milagro} -l:libmilagro.a
OBJS := test_rsa test_ecm test_ecdh

all:
	${CC} ${CFLAGS} -o test_rsa  test_rsa.c ${LDADD}
	${CC} ${CFLAGS} -o test_ecm  test_ecm.c ${LDADD}
	${CC} ${CFLAGS} -o test_ecdh test_ecdh.c ${LDADD}

check: all
	@echo "------\nRSA tests\n------"
	@./test_rsa
	@echo "------\nECM tests\n------"
	@./test_ecm
	@echo "------\nECDH tests\n------"
	@./test_ecdh

clean:
	rm -f ${OBJS}
