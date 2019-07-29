#!/usr/bin/env bash
python2 tools/esptool.py \
    --port=/dev/ttyUSB0 \
    write_flash \
    -fm=dio\
    -fs=32m 0x00000 \
    firmware/nodemcu-master-12-modules-2019-04-24-03-14-11-float.bin
