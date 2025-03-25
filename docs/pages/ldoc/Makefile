OUTPUT=o

all:
	@mkdir -p ${OUTPUT}
	@ldoc -X .
	@mv ${OUTPUT}/index.html ${OUTPUT}/README.md

clean:
	@rm -fr ${OUTPUT}
