#!/bin/bash

# check for whether we're clang or gcc
# setup the right options depending on the environment variables
# run the build

if [ "${CC}" == "clang" ]; then
    if [ "${MAKE}" == "1" ]; then
	make config T=x86_64-native-linuxapp-clang
    fi
elif [ "${CC}" == "gcc" ]; then
    if [ "${MAKE}" == "1" ]; then
	make config T=x86_64-native-linuxapp-gcc
    fi
else
	echo "compiler env variable not set"
	exit 1
fi

if [ "${MAKE}" == "1" ]; then
    make all
else
    meson build
    ninja -C build
fi
