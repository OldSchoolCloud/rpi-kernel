#!/usr/bin/env bash

SUPPORTED_FLAVOURS=( v8 2712 )
SELECTED_FLAVOURS=( "${@:-"${SUPPORTED_FLAVOURS[@]}"}" )

# From
#   https://wiki.debian.org/HowToCrossBuildAnOfficialDebianKernelPackage
ARCH=arm64
FEATURESET=rpi

echo "Selected flavours: ${SELECTED_FLAVOURS[@]}"

# Validate that selected flavours are indeed supported
for selected_flavour in "${SELECTED_FLAVOURS[@]}";
do
  case "${SUPPORTED_FLAVOURS[@]}" in
      (*"$selected_flavour"*) ;;
      (*)
          echo "Kernel flavour not supported: $selected_flavour"
          echo "Supported flavours: ${SUPPORTED_FLAVOURS[@]}"
          exit 1
          ;;
  esac
done

build_kernel() {

  flavour="$1"

  echo "Building for kernel flavour: $flavour"
  pwd
  cd /opt/kernel
  pwd

  apt-cache depends linux-image-rpi-"$flavour" | grep Depends: > deb.list

  sed -i -e 's/[<>|:]//g' deb.list
  sed -i -e 's/Depends//g' deb.list
  sed -i -e 's/ //g' deb.list
  filename="deb.list"

  # Here the file will contain something like linux-image-6.6.20+rpt-rpi-<version>
  # we want to check if the deb file already exists, eventually build
  while read -r line
  do
      name="$line"
      if find /output -name "$name*.deb" -printf 1 -quit | grep -q 1
      then
          echo "Kernel packages are already available. Nothing to do here."
          return 0
      fi
  done < "$filename"

  # If we get here we didn't find the relevant deb package. Build and install it
  apt-get update
  apt-get source linux-image-rpi-"$flavour"

  export "$(dpkg-architecture -a$ARCH)"
  export PATH=/usr/lib/ccache:$PATH
  # Build profiles is from: https://salsa.debian.org/kernel-team/linux/blob/master/debian/README.source
  export DEB_BUILD_PROFILES="cross nopython nodoc pkg.linux.notools"
  # Enable build in parallel
  export MAKEFLAGS="-j$(($(nproc)*2))"
  # Disable -dbg (debug) package is only possible when distribution="UNRELEASED" in debian/changelog
  export DEBIAN_KERNEL_DISABLE_DEBUG=
  [ "$(dpkg-parsechangelog --show-field Distribution)" = "UNRELEASED" ] &&
    export DEBIAN_KERNEL_DISABLE_DEBUG=yes
    
  export CROSS_COMPILE=aarch64-linux-gnu-
  
  _source_dir=$(find .  -maxdepth 1 -type d -name "linux-*")
  cd "$_source_dir" || return 1

  if find ./debian/config/arm64/rpi/ -name "config.$flavour" -printf 1 -quit | grep -q 1
  then
      pwd
      cp ../scripts/"$flavour"-config-overlay ./debian/config/arm64/rpi/config."$flavour"
      make -f ./debian/rules.gen binary-arch_"$ARCH"_"$FEATURESET"_"$flavour"
  else
      echo "$flavour" Configuration file not found. Perhaps the source structure has changed?
  fi

  mv /opt/kernel/*.deb /output

}

apt-get update

# Build all selected kernel flavours
for selected_flavour in "${SUPPORTED_FLAVOURS[@]}";
do
  build_kernel "$selected_flavour"
done

# Update the package index
cd /output || exit 1
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

sleep 2m
