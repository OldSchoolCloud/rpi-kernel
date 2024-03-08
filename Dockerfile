FROM ubuntu:22.04
ARG VERSION=1.20230405
ARG KERNEL=kernel8
ENV VERSION=$VERSION
ENV KERNEL=$KERNEL

RUN echo $VERSION

WORKDIR /opt/kernel
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential gcc \
    ca-certificates kmod \
    git bc bison flex libssl-dev \
    make libc6-dev libncurses5-dev \
    crossbuild-essential-arm64 dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch $VERSION https://github.com/raspberrypi/linux
#COPY export_kernel.sh .

WORKDIR /opt/kernel/linux
RUN make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
RUN sed -i 's/CONFIG_LOCALVERSION="-v8"/CONFIG_LOCALVERSION="-v8-48"/g' .config
# Enable 48 bit memory page size
RUN sed -i 's/CONFIG_ARM64_VA_BITS_39=y/# CONFIG_ARM64_VA_BITS_39 is not set/g' .config
RUN sed -i 's/# CONFIG_ARM64_VA_BITS_48 is not set/CONFIG_ARM64_VA_BITS_48=y/g' .config
RUN sed -i 's/CONFIG_ARM64_VA_BITS=39/CONFIG_ARM64_VA_BITS=48/g' .config
# Build kernel
RUN make -j$(( $(nproc) * 2 )) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- deb-pkg
