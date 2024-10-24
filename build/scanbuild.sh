#!/bin/sh
# wrapper script passed to ninja in build/sonarqube.mk
scan-build -v -plist "$@"
