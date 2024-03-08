FROM ubuntu:22.04
ARG VERSION=stable_20240124
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
    rsync cpio \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch $VERSION https://github.com/raspberrypi/linux
COPY build_kernel.sh .

RUN ./build_kernel.sh
