LIB := ../../meson
LDADD := -L${LIB} -lzenroom
CFLAGS += -I../../src
all:
	${CC} ${CFLAGS} -o hash hash.c ${LDADD}
	LD_LIBRARY_PATH=${LIB} ./hash

