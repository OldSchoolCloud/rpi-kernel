#!/usr/bin/env bash

cd /opt/kernel/linux

_kernel_version=$(make kernelversion)

echo "Kernel version is $_kernel_version"
echo "Kernel local version is $_arg_kernel_localversion"

echo "Cleaning up the directory"
make mrproper

echo "Creating initial .config"
make make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig \
    || die "Unable to create initial .config" 1

echo "Setting kernel local version"
./scripts/config --set-str  CONFIG_LOCALVERSION "-v8-48"

echo "Enabling 48 bit memory page size"
./scripts/config --disable CONFIG_ARM64_VA_BITS_39
./scripts/config --enable CONFIG_ARM64_VA_BITS_48
./scripts/config --set-val CONFIG_ARM64_VA_BITS 48

# Validate config changes
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig

echo "Building kernel and generating .deb packages"
make -j$(( $(nproc) * 2 )) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- deb-pkg \
    || die "Unable to build or package kernel" 1
