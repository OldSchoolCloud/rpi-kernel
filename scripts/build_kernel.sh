#!/usr/bin/env bash

apt-get update

apt-cache depends linux-image-rpi-v8 | grep Depends: > deb.list

sed -i -e 's/[<>|:]//g' deb.list
sed -i -e 's/Depends//g' deb.list
sed -i -e 's/ //g' deb.list
filename="deb.list"

# here the file will contain something like linux-image-6.6.20+rpt-rpi-v8
# we want to check if the deb file already exists, eventually build
while read -r line
do
    name="$line"
    if find /output -name "$name*.deb" -printf 1 -quit | grep -q 1
    then
        echo Kernel packages are already available. Nothing to do here.
        exit 0
    fi
done < "$filename"

# If we get here we didn't find the relevant deb package. Build and install it
apt-get update
apt-get source linux-image-rpi-v8

_source_dir=$(find .  -maxdepth 1 -type d -name "linux-*")
cd $_source_dir

if find ./debian/config/arm64/rpi/ -name "config.v8" -printf 1 -quit | grep -q 1
then
    cp ../scripts/v8-config-overlay ./debian/config/arm64/rpi/config.v8
    cat ./debian/config/arm64/rpi/config.v8
else
    echo V8 Configuration file not found. Perhaps the source structure has changed?
    exit 1
fi

make -f ./debian/rules.gen -j$(( $(nproc) * 2 )) binary-arch_arm64_rpi_v8
mv /opt/kernel/*.deb /output

# Update the package index
cd /output
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
