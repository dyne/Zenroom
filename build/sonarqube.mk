
## Initialize build defaults
include build/init.mk

## TODO: test with sonarqube server (we moved out of ow2)
SONAR_LOGIN ?= ""
SONAR_HOST_URL := https://sonarqube.ow2.org
SCANBUILD_SCRIPT := $(pwd)/build/scanbuild.sh

# Needs clang-tools for scan-build

COMPILER := clang

cflags += ${cflags_debug} -fPIC
# activate CCACHE etc.
include build/plugins.mk

sonarqube: ## build a sonarqube cpp static analysis
	$(info Configure login token in build/sonarqube.sh)
	$(MAKE) -f build/meson.mk deps COMPILER=clang
	$(MAKE) -f build/meson.mk prepare COMPILER=clang
	$(MAKE) -f build/meson.mk config COMPILER=clang
	SCANBUILD=${SCANBUILD_SCRIPT} ninja -C meson scan-build
	@docker pull sonarqube
	@cp -v build/sonar-project.properties .
	@docker run --rm -e SONAR_HOST_URL=${SONAR_HOST_URL} \
		-e SONAR_LOGIN=${SONAR_LOGIN} \
		-v ${pwd}:/usr/src sonarsource/sonar-scanner-cli \
		-Dsonar.projectKey=zenroom

# sonarqube debug -X
