#!/usr/bin/env bash

set -euo pipefail

shellcheck --shell=bash --external-sources --check-sourced \
  bin/* lib/commands/* --source-path=lib/
shellcheck --shell=bash --external-sources --check-sourced \
  lib/goapp-plugin/bin/* --source-path=lib/goapp-plugin/lib/
