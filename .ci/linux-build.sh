#!/bin/sh -xe

on_error() {
    if [ $? = 0 ]; then
        exit
    fi
    FILES_TO_PRINT="build/meson-logs/testlog.txt build/.ninja_log build/meson-logs/meson-log.txt"

    for pr_file in $FILES_TO_PRINT; do
        if [ -e "$pr_file" ]; then
            cat "$pr_file"
        fi
    done
}
trap on_error EXIT

if [ "$AARCH64" = "1" ]; then
    # convert the arch specifier
    OPTS="$OPTS --cross-file config/arm/arm64_armv8_linux_gcc"
fi

OPTS="$OPTS --default-library=$DEF_LIB"
meson build --werror -Dexamples=all $OPTS
ninja -C build

if [ "$AARCH64" != "1" ]; then
    sudo meson test -C build --suite fast-tests
    sudo meson test -C build --suite perf-tests
    sudo meson test -C build --suite driver-tests
    sudo meson test -C build --suite debug-tests
fi
