#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

hyperfine -w 5 -N $(ls -f zig-out/bin/day*)