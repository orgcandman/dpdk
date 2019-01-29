#!/bin/bash

python3.5 -m pip install --upgrade meson --user

echo "ARM64 is [ ${ARM64} ]"

if [ "${ARM64}" == "1" ]; then
    # need to build & install libnuma
    # This will only be minimal support for now.
    ARM64_TOOL_URL='https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz'
    ARM64_TOOL="linaro-arm-tool"
    NUMA_GIT_URL="https://github.com/numactl/numactl.git"

    wget -O "${ARM64_TOOL}.tar.xz" "${ARM64_TOOL_URL}"
    tar -xf "${ARM64_TOOL}.tar.xz"
    mv gcc-linaro* "${ARM64_TOOL}"
    export PATH=$PATH:$(pwd)/${ARM64_TOOL}/bin
    git clone "${NUMA_GIT_URL}"
    cd numactl
    git checkout v2.0.11
    ./autogen.sh
    autoconf -i
    mkdir numa_bin
    ./configure --host=aarch64-linux-gnu CC=aarch64-linux-gnu-gcc --prefix=$(pwd)/numa_bin
    make install # install numa
    cd ..
    cp numactl/numa_bin/include/numa*.h "${ARM64_TOOL}/aarch64-linux-gnu/libc/usr/include/"
    cp numactl/numa_bin/lib/libnuma.* "${ARM64_TOOL}/aarch64-linux-gnu/lib64/"
    cp numactl/numa_bin/lib/libnuma.* "${ARM64_TOOL}/lib/"
fi
