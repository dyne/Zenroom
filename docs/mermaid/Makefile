mermaid := mmdc -p puppeteer-config.json -c mermaid-config.json
SOURCES = ecdh_keygen.mrm ecdh_crypt.mrm aes_crypt.mrm
GRAPHS := $(SOURCES:.mrm=.svg)

# ecdh_keygen.svg aes_crypt.svg

all: ${GRAPHS}
	cp ${GRAPHS} ../website/docs/img/

#	${mermaid} -i ${SOURCES} -b transparent -t neutral
#	mmdc -p puppeteer-config.json -i ${SOURCES} -o svg -b transparent -t neutral


%.svg: %.mrm
	${mermaid} -i $< -o $@ -b transparent

clean:
	rm -f $(GRAPHS)
