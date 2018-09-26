
win: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src win-exe

win-dll: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		 make -C src win-dll
