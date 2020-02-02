linux-luarock: cflags := -O3 ${cflags_protection} -fPIE -fPIC
linux-luarock: cflags += -shared -DLIBRARY
linux-luarock: apply-patches milagro lua53 embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src luarock
