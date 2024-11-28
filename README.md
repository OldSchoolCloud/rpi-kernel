# Raspberry PI kernel build container

[![stability-wip](https://img.shields.io/badge/stability-wip-lightgrey.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#work-in-progress)

A small container to build the kernel using CONFIG_ARM64_VA_BITS_48 solving the issues
related to Google's tcmalloc incompatibility.

https://github.com/raspberrypi/linux/issues/4375

It builds the kernel using the default RPI. Improvement pull requests are welcome.

It builds the deb.

## How to build the kernel

By default, the script will build all supported kernel flavours (ie. `v8`, `2712`)
Edit the `docker-compose.yaml` if you want to override and select the kernel flavours to build.  

For example:

```yaml
    command:
      - bash
      - -c
      - "scripts/build_kernel.sh v8"
```

The following command will build the kernel .deb packages and save them in the `debs` directory.
It will also generate the `Packages.gz` file to run the apt repository using apache.

```bash
docker compose run --build --rm builder
```

Once built the dockerfile will retain the .deb files in the image,
subsequent builds will use the cache and won't recompile the kernel.

You can run the apt repository using:

```bash
docker compose up --build apt
```

NOTE: The apt repository is only a proof of concept meant to be run in a local environment
with limited network connectivity. Before using it on public networks,
please review configuration, especially for security.

## What is missing

The produced `deb` package has the same name as the original package, which could create
naming collisions. Ideally we'd like to change the LOCALVERSION so we can install this
package without replacing the original one. (Reference discussion: https://github.com/RPi-Distro/repo/issues/368)
