#!/usr/bin/env bash

SUPPORTED_FLAVOURS=( v8 2712 )
FLAVOUR=$1

case " ${SUPPORTED_FLAVOURS[@]} " in
    (*" $FLAVOUR "*) echo "Building for kernel version: $FLAVOUR" ;;
    (*)
        echo "Kernel version not supported: $FLAVOUR"
        echo "Supported versions: ${SUPPORTED_FLAVOURS[@]}"
        exit 1
        ;;

esac

apt-get update

apt-cache depends linux-image-rpi-"$FLAVOUR" | grep Depends: > deb.list

sed -i -e 's/[<>|:]//g' deb.list
sed -i -e 's/Depends//g' deb.list
sed -i -e 's/ //g' deb.list
filename="deb.list"

# here the file will contain something like linux-image-6.6.20+rpt-rpi-<version>
# we want to check if the deb file already exists, eventually build
while read -r line
do
    name="$line"
    if find /output/"$FLAVOUR" -name "$name*.deb" -printf 1 -quit | grep -q 1
    then
        echo "Kernel packages are already available. Nothing to do here."
        exit 0
    fi
done < "$filename"

# If we get here we didn't find the relevant deb package. Build and install it
apt-get update
apt-get source linux-image-rpi-"$FLAVOUR"

# From
#   https://wiki.debian.org/HowToCrossBuildAnOfficialDebianKernelPackage
ARCH=arm64
FEATURESET=rpi

export $(dpkg-architecture -a$ARCH)
export PATH=/usr/lib/ccache:$PATH
# Build profiles is from: https://salsa.debian.org/kernel-team/linux/blob/master/debian/README.source
export DEB_BUILD_PROFILES="cross nopython nodoc pkg.linux.notools"
# Enable build in parallel
export MAKEFLAGS="-j$(($(nproc)*2))"
# Disable -dbg (debug) package is only possible when distribution="UNRELEASED" in debian/changelog
export DEBIAN_KERNEL_DISABLE_DEBUG=
[ "$(dpkg-parsechangelog --show-field Distribution)" = "UNRELEASED" ] &&
  export DEBIAN_KERNEL_DISABLE_DEBUG=yes

_source_dir=$(find .  -maxdepth 1 -type d -name "linux-*")
cd $_source_dir

if find ./debian/config/arm64/rpi/ -name "config.$FLAVOUR" -printf 1 -quit | grep -q 1
then
    cp ../scripts/"$FLAVOUR"-config-overlay ./debian/config/arm64/rpi/config."$FLAVOUR"
else
    echo "$FLAVOUR" Configuration file not found. Perhaps the source structure has changed?
    exit 1
fi

make -f ./debian/rules.gen binary-arch_"$ARCH"_"$FEATURESET"_"$FLAVOUR"
mkdir -p /output/"$FLAVOUR"
mv /opt/kernel/*.deb /output/"$FLAVOUR"

# Update the package index
cd /output/"$FLAVOUR"
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
