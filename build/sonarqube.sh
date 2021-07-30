#!/bin/sh

docker pull sonarqube

# sonarqube debug -X

SONAR_LOGIN=""

docker run --rm -e SONAR_HOST_URL="https://sonarqube.ow2.org" \
	-e SONAR_LOGIN="$SONAR_LOGIN" \
	-v "$HOME/devel/zenroom/:/usr/src" sonarsource/sonar-scanner-cli \
	-Dsonar.projectKey=zenroom
