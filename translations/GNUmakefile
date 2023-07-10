
SOURCES := $(shell find ../src/lua -name 'zencode_*')

all:
	xgettext  --copyright-holder="Dyne.org foundation" \
			  --package-name="Zenroom" --package-version="${1:-latest}" \
			  --msgid-bugs-address="info@dyne.org" \
			  --sort-by-file \
			  -kWhen -kIfWhen -kGiven -kThen -kwarn -kerror -kassert \
			  -d zenroom -L lua  --from-code=UTF-8 ${SOURCES}

clean:
	rm *.po
