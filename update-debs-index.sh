#!/usr/bin/env bash

cd /output
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
