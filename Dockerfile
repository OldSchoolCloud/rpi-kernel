FROM ubuntu:22.04

WORKDIR /opt/kernel
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential gcc \
    ca-certificates kmod \
    git bc bison flex libssl-dev \
    make libc6-dev libncurses5-dev \
    crossbuild-essential-arm64 dpkg-dev \
    rsync cpio \
    && rm -rf /var/lib/apt/lists/*

COPY upstream-kernel /opt/kernel/linux
COPY build_kernel.sh .

RUN ./build_kernel.sh
