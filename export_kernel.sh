#!/usr/bin/env bash

mkdir -p /opt/bin/$VERSION/boot/overlays

env PATH=$PATH make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=/opt/bin/$VERSION modules_install
cp arch/arm64/boot/Image /opt/bin/$VERSION/boot/$KERNEL.img
cp arch/arm64/boot/dts/broadcom/*.dtb /opt/bin/$VERSION/boot/
cp arch/arm64/boot/dts/overlays/*.dtb* /opt/bin/$VERSION/boot/overlays/
cp arch/arm64/boot/dts/overlays/README /opt/bin/$VERSION/boot/overlays/
