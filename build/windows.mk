
win: apply-patches lua53 milagro embed-lua lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src win-exe

win-dll: apply-patches lua53 milagro embed-lua lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		 make -C src win-dll

cyg: apply-patches lua53 milagro embed-lua lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src cyg-exe

cyg-dll: apply-patches lua53 milagro embed-lua lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src cyg-dll
