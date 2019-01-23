#!/bin/bash

# check for whether we're clang or gcc
# setup the right options depending on the environment variables
# run the build

# Just used for the 'classic' configuration system (ie: make)
set_conf() {
    c="$1/.config"
    shift

    if grep -q "$1" "$c"; then
        sed -i "s:^$1=.*$:$1=$2:g" $c
    else
        echo $1=$2 >> "$c"
    fi
}


if [ "${MAKE}" == "1" ]; then
    make config T=x86_64-native-linuxapp-${CC}
    if [ "${SHARED}" == "1" ]; then
        set_conf build CONFIG_RTE_BUILD_SHARED_LIB y
    fi

    if [ "${KERNEL}" == "1" ]; then
        echo Unsupported kernel builds at the moment
    fi

    make all
else
    meson build
    ninja -C build
fi
