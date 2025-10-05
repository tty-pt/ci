#!/bin/sh
qemu-system-x86_64 -m 512 -cdrom alpine-standard-3.22.1-x86_64.iso -boot d -hda alpine.qcow2
