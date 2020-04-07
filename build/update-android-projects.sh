#!/usr/bin/env bash

LIB_DST_PATH=${LIB_DST_PATH:=${PWD}/target/android/jniLibs}
ZEN_ANDROID_PROJECTS=${ZEN_UPDATE_ANDROID_PROJECTS:=${*}}
ANDROID_PROJECT_LIB_PATH=app/src/main

for project_path in ${ZEN_UPDATE_ANDROID_PROJECTS}; do 
	echo "${0}: Updating Android Project jniLibs into ${project_path}/${ANDROID_PROJECT_LIB_PATH}"
	cp -r ${LIB_DST_PATH} ${project_path}/${ANDROID_PROJECT_LIB_PATH}
done
