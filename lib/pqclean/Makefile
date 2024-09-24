# TODO: duplicate member names (cbd, symmetric shake) across ML- and others
#       giving a warning on iOS, presumably can ignore as only on filename

CFLAGS ?= -O2 -I../../src -I. -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
CC ?= gcc

COMMON=sha2.o fips202.o

# LIB=libkyber512_clean.a
KIBER512=kyber512/cbd.o kyber512/indcpa.o kyber512/kem.o kyber512/ntt.o kyber512/poly.o kyber512/polyvec.o kyber512/reduce.o kyber512/symmetric-shake.o kyber512/verify.o

# LIB=libdilithium2_clean.a
DILITHIUM2=dilithium2/ntt.o dilithium2/packing.o dilithium2/poly.o dilithium2/polyvec.o dilithium2/reduce.o dilithium2/rounding.o dilithium2/sign.o dilithium2/symmetric-shake.o

ML_DSA_44=ml-dsa-44/ntt.o ml-dsa-44/poly.o ml-dsa-44/reduce.o ml-dsa-44/sign.o ml-dsa-44/packing.o ml-dsa-44/polyvec.o ml-dsa-44/rounding.o ml-dsa-44/symmetric-shake.o ml-dsa-44/zen_sign.o

ML_KEM_512=ml-kem-512/ntt.o ml-kem-512/reduce.o ml-kem-512/symmetric-shake.o ml-kem-512/verify.o ml-kem-512/poly.o ml-kem-512/cbd.o ml-kem-512/kem.o ml-kem-512/polyvec.o ml-kem-512/indcpa.o

# LIB=libsntrup761_clean.a
SNTRUP761=sntrup761/crypto_core_inv3sntrup761.o sntrup761/crypto_core_invsntrup761.o sntrup761/crypto_core_mult3sntrup761.o sntrup761/crypto_core_multsntrup761.o sntrup761/crypto_core_scale3sntrup761.o sntrup761/crypto_core_weightsntrup761.o sntrup761/crypto_core_wforcesntrup761.o sntrup761/crypto_decode_761x1531.o sntrup761/crypto_decode_761x3.o sntrup761/crypto_decode_761x4591.o sntrup761/crypto_decode_761xint16.o sntrup761/crypto_decode_761xint32.o sntrup761/crypto_encode_761x1531.o sntrup761/crypto_encode_761x1531round.o sntrup761/crypto_encode_761x3.o sntrup761/crypto_encode_761x4591.o sntrup761/crypto_encode_761xfreeze3.o sntrup761/crypto_encode_761xint16.o sntrup761/crypto_encode_int16.o sntrup761/crypto_sort_int32.o sntrup761/crypto_sort_uint32.o sntrup761/crypto_verify_1039.o sntrup761/kem.o

all: build/libqpz.a

build/libqpz.a: ${COMMON} ${KIBER512} ${DILITHIUM2} ${ML_DSA_44} ${ML_KEM_512} ${SNTRUP761}
	${AR} -r libqpz.a ${COMMON} ${KIBER512} ${DILITHIUM2} ${ML_DSA_44} ${ML_KEM_512} ${SNTRUP761}

clean:
	rm -f *.a
	rm -f ${COMMON}
	rm -f ${KIBER512} ${DILITHIUM2} ${ML_DSA_44} ${ML_KEM_512} ${SNTRUP761}
