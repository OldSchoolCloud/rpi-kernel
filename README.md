# Raspberry PI kernel build container

A small container to build the kernel using CONFIG_ARM64_VA_BITS_48 solving the issues
related to Google's tcmalloc incompatibility.

https://github.com/raspberrypi/linux/issues/4375

It builds the kernel using `bcm2711_defconfig` to be used for RPI4. Improvement pull requests are welcome.

It keeps track of the upstream kernel using github tags, hoping it will continue to use `stable_XXXXXXXX` format.

## How to build the kernel

This command will build the kernel .deb packages and save them in the `debs` directory.
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
with limited network connectivity. Before using it on public networks security,
please review configuration, especially for security.
