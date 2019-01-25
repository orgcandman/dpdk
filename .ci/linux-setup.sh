#!/bin/sh

if [ "${NINJABUILD}" != "1" ]; then
    exit 0
fi


python3.5 -m pip install --upgrade meson --user
