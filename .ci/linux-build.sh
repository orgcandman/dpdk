#!/bin/sh

# check for whether we're clang or gcc
# setup the right options depending on the environment variables
# run the build

#TODO: check if CC == "", exit with some error
if [ "${CC}" == "clang" ]
then
	make config T=x86_64-native-linuxapp-clang
elif [ "${CC}" == "gcc" ]
	make config T=x86_64-native-linuxapp-gcc
fi

make all
