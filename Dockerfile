FROM python:3-bookworm as BUILDER2

WORKDIR /opt/kernel
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    dpkg-cross build-essential gcc \
    ca-certificates kmod \
    git bc bison flex libssl-dev \
    make libc6-dev libncurses5-dev \
    crossbuild-essential-arm64 dpkg-dev \
    rsync cpio debhelper quilt dh-exec \
    && rm -rf /var/lib/apt/lists/*

#TODO: Copy gpg key and remove trusted from the  file
COPY raspi.list /etc/apt/sources.list.d/raspi.list

# Just to make sure it works
RUN apt-get update \
    && rm -rf /var/lib/apt/lists/*

COPY scripts ./scripts
# Make sure scripts are executable
RUN chmod ugo+x ./scripts/*.sh

FROM httpd:2 as APT

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/apache2/htdocs/debs
