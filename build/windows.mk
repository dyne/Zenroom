
win: ${BUILDS}
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src win-exe

win-debug: ${BUILDS}
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src win-exe

win-dll: ${BUILDS}
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		 make -C src win-dll

cyg: ${BUILDS}
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src cyg-exe

cyg-dll: ${BUILDS}
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src cyg-dll
