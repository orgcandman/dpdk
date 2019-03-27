#!/bin/sh

sudo python3 -m pip install --upgrade meson

cat /proc/meminfo
sudo sh -c 'echo 1024 > /proc/sys/vm/nr_hugepages'
cat /proc/meminfo

