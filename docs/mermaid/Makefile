mermaid := mmdc -p puppeteer-config.json -c mermaid-config.json
SOURCES = ecdh_keygen.mrm ecdh_crypt.mrm aes_crypt.mrm ecdsa_sign.mrm
GRAPHS := $(SOURCES:.mrm=.svg)

all: ${GRAPHS}
	cp ${GRAPHS} ../website/docs/img/

%.svg: %.mrm
	${mermaid} -i $< -o $@ -b transparent

clean:
	rm -f $(GRAPHS)
