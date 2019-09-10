SOURCE_VERSION = $(shell git describe --tags --always --dirty --abbrev=6)

GOCMD = go
GOBUILD = $(GOCMD) build
GOINSTALL = $(GOCMD) install
GOTEST = $(GOCMD) test -v -covermode=atomic
GOBENCH = $(GOCMD) test -benchmem -bench=.

default: help

test: ## Testing suite
	LD_LIBRARY_PATH=./zenroom $(GOTEST)
.PHONY: test

benchmark: ## Run Benchmarks
	LD_LIBRARY_PATH=./zenroom $(GOBENCH)
.PHONY: benchmark
# 'help' parses the Makefile and displays the help text
help:
	@echo "Please use 'make <target>' where <target> is one of"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help