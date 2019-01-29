#!/bin/bash

# check for whether we're clang or gcc
# setup the right options depending on the environment variables
# run the build

# Just used for the 'classic' configuration system (ie: make)
set_conf() {
    echo "[BUILT WITH $2 SET TO $3]"
    c="$1/.config"
    shift

    if grep -q "$1" "$c"; then
        sed -i "s:^$1=.*$:$1=$2:g" $c
    else
        echo $1=$2 >> "$c"
    fi
}

BUILD_ARCH="x86_64-native-linuxapp-"

if [ "${ARM64}" == "1" ]; then
    # convert the arch specifier
    BUILD_ARCH="arm64-armv8a-linuxapp-"
    ARM64_TOOL="linaro-arm-tool"
    export PATH=$PATH:$(pwd)/${ARM64_TOOL}/bin
fi


if [ "${NINJABUILD}" == "1" ]; then
    OPTS=""

    DEF_LIB="static"
    if [ "${SHARED}" == "1" ]; then
        DEF_LIB="shared"
    fi

    if [ "${KERNEL}" == "1" ]; then
        OPTS="-Denable_kmods=false"
    fi

    if [ "${ARM64}" == "1" ]; then
        OPTS="${OPTS} --cross-file meson_cross_aarch64_${CC}.txt"
    fi

    OPTS="$OPTS --default-library=$DEF_LIB"
    meson build --werror -Dexamples=all ${OPTS}
    ninja -C build
else
    EXTRA_OPTS=""

    make config T="${BUILD_ARCH}${CC}"

    set_conf build CONFIG_RTE_KNI_KMOD n
    set_conf build CONFIG_RTE_EAL_IGB_UIO n

    if dpkg --list | grep -q zlib1g ; then
        set_conf build CONFIG_RTE_LIBRTE_PMD_ZLIB y
    fi

    if dpkg --list | grep -q libpcap-dev ; then
        set_conf build CONFIG_RTE_PORT_PCAP y
    fi

    if [ "${SHARED}" == "1" ]; then
        set_conf build CONFIG_RTE_BUILD_SHARED_LIB y
    fi

    if [ "${KERNEL}" == "1" ]; then
        echo Unsupported kernel builds at the moment
    fi

    if [ "${ARM64}" == "1" ]; then
        EXTRA_OPTS="CROSS=aarch64-linux-gnu-"

        # need to turn off these extras
        set_conf build CONFIG_RTE_PORT_PCAP n
        set_conf build CONFIG_RTE_LIBRTE_PMD_ZLIB n

        # convert the CC/CXX variables
        export CC=aarch64-linux-gnu-${CC}
        export CXX=aarch64-linux-gnu-${CXX}
        export AR=aarch64-linux-gnu-ar
        export STRIP=aarch64-linux-gnu-strip
    fi

    make all ${EXTRA_OPTS}
fi
