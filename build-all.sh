#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

for day in $(ls -d day*); do zig build "$day" -Doptimize=ReleaseFast; done