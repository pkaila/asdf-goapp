#!/usr/bin/env bash

# Most of this file is copied and adapted from the excellent asdf-pyapp plugin
# by Andy Mroczkowski. The project can be found from https://github.com/amrox/asdf-pyapp
# and is licensed under the license included in the LICENSE -file in the root of this project.

set -euo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck disable=SC1091 # File is only present after installation
source "$(dirname "$script_dir")/plugin.config"

ASDF_GOAPP_RESOLVED_GO_PATH=

if [[ ${ASDF_GOAPP_DEBUG:-} -eq 1 ]]; then
  # In debug mode, dump everything to a log file
  # From: https://github.com/amrox/asdf-pyapp/blob/master/lib/utils.bash

  ASDF_GOAPP_DEBUG_LOG_PATH="/tmp/${ASDF_GOAPP_PLUGIN_NAME}-debug.log"
  mkdir -p "$(dirname "$ASDF_GOAPP_DEBUG_LOG_PATH")"

  printf "\n\n-------- %s ----------\n\n" "$(date)" >>"$ASDF_GOAPP_DEBUG_LOG_PATH"

  exec > >(tee -ia "$ASDF_GOAPP_DEBUG_LOG_PATH")
  exec 2> >(tee -ia "$ASDF_GOAPP_DEBUG_LOG_PATH" >&2)

  exec 19>>"$ASDF_GOAPP_DEBUG_LOG_PATH"
  export BASH_XTRACEFD=19
  set -x
fi

fail() {
  echo >&2 -e "${ASDF_GOAPP_PLUGIN_NAME}: [ERROR] $*"
  exit 1
}

log() {
  if [[ ${ASDF_GOAPP_DEBUG:-} -eq 1 ]]; then
    echo >&2 -e "${ASDF_GOAPP_PLUGIN_NAME}: $*"
  fi
}

get_go_version() {
  local go_path="$1"
  local regex='go version go([^ ]+) .+'

  go_version_raw=$("$go_path" version)

  if [[ $go_version_raw =~ $regex ]]; then
    echo -n "${BASH_REMATCH[1]}"
  else
    fail "Unable to determine go version"
  fi
}

resolve_go_path() {
  # if ASDF_GOAPP_DEFAULT_GO_PATH is set, use it, else:
  # 1. try $(asdf which go)
  # 2. try $(which go)

  if [ -n "${ASDF_GOAPP_DEFAULT_GO_PATH+x}" ]; then
    ASDF_GOAPP_RESOLVED_GO_PATH="$ASDF_GOAPP_DEFAULT_GO_PATH"
    return
  fi

  # cd to $HOME to avoid picking up a local go from .tool-versions
  pushd "$HOME" >/dev/null || fail "Failed to pushd \$HOME"

  # run direnv in $HOME to escape any direnv we might already be in
  if type -P direnv &>/dev/null; then
    eval "$(DIRENV_LOG_FORMAT= direnv export bash)"
  fi

  local gos=()

  local asdf_go
  if asdf_go=$(asdf which go 2>/dev/null); then
    gos+=("$asdf_go")
  else
    local global_go
    global_go=$(which go)
    gos+=("$global_go")
  fi

  for g in "${gos[@]}"; do
    local go_version
    log "Testing '$g' ..."
    go_version=$(get_go_version "$g")
    if [[ $go_version =~ ^([0-9]+)\.([0-9]+)\. ]]; then
      local go_version_major=${BASH_REMATCH[1]}
      local go_version_minor=${BASH_REMATCH[2]}
      if [ "$go_version_major" -ge 1 ] && [ "$go_version_minor" -ge 16 ]; then
        ASDF_GOAPP_RESOLVED_GO_PATH="$g"
        break
      fi
    else
      continue
    fi
  done

  popd >/dev/null || fail "Failed to popd"

  if [ -z "$ASDF_GOAPP_RESOLVED_GO_PATH" ]; then
    fail "Failed to find go >= 1.16"
  else
    log "Using go at '$ASDF_GOAPP_RESOLVED_GO_PATH'"
  fi
}

list_all_versions() {
  resolve_go_path
  $ASDF_GOAPP_RESOLVED_GO_PATH list -versions -m "$ASDF_GOAPP_MODULE" | cut -d' ' -f2-
}

install_version() {
  # local install_type="$1"
  local full_version="$2"
  local install_path="$3"
  local bin_path="${install_path%/bin}/bin"
  local gobin=$bin_path
  # local goroot="${bin_path%/bin}"
  local gotooldir=$bin_path

  # shellcheck disable=SC2206
  local versions=(${full_version//\@/ })
  local module_version=${versions[0]}
  if [ "${#versions[@]}" -gt 1 ]; then
    if ! asdf plugin list | grep golang; then
      fail "Cannot install $ASDF_GOAPP_PLUGIN_NAME $full_version - asdf golang plugin is not installed!"
    fi

    go_version=${versions[1]}
    if [[ $go_version =~ ^([0-9]+)\.([0-9]+)\. ]]; then
      local go_version_major=${BASH_REMATCH[1]}
      local go_version_minor=${BASH_REMATCH[2]}
      if ! [[ "$go_version_major" -ge 1 && "$go_version_minor" -ge 16 ]]; then
        fail "Given go version is not >= 1.16, cannot proceed with installation"
      fi
    else
      fail "Unable to parse go version to validate it is of version >= 1.16, cannot proceed with installation"
    fi

    asdf install golang "$go_version"
    ASDF_GOAPP_RESOLVED_GO_PATH=$(ASDF_GOLANG_VERSION="$go_version" asdf which go)
  else
    resolve_go_path
  fi

  (
    mkdir -p "$bin_path"
    GOBIN=$gobin GOTOOLDIR=$gotooldir $ASDF_GOAPP_RESOLVED_GO_PATH install "$ASDF_GOAPP_PACKAGE_PATH@$module_version" ||
      fail "Go install failed."

    test -n "$(
      shopt -s nullglob
      echo "$bin_path"/*
    )" || fail "No binaries were installed."
    for b in "$bin_path"/*; do
      test -x "$b" || fail "Binary $b is not executable"
    done

    echo "$ASDF_GOAPP_PLUGIN_NAME $module_version installation was successful!"
  ) || (
    # The download directory will not be automatically removed, let's remove it here to
    # remove an unnecessary mkdir warning when trying to re-install the app
    # There is no need to keep the download directory around as we never downloaded anything.
    test ! -z ${ASDF_DOWNLOAD_PATH+x} && test -d "$ASDF_DOWNLOAD_PATH" && rm -rf "$ASDF_DOWNLOAD_PATH"

    fail "An error occurred while installing $ASDF_GOAPP_PLUGIN_NAME $module_version."
  )
}
