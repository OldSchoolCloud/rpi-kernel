FROM ubuntu:22.04 as BUILDER
ARG VERSION
ENV VERSION=$VERSION

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
# Make sure this becomes executable
RUN chmod ugo+x ./build_kernel.sh

RUN ./build_kernel.sh
COPY update-debs-index.sh .
# Make sure this becomes executable
RUN chmod ugo+x ./update-debs-index.sh

FROM httpd:2 as APT

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/apache2/htdocs/debs
COPY update-debs-index.sh /bin/update-debs.sh
