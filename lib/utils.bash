#!/usr/bin/env bash

set -euo pipefail

ASDF_GOAPP_PLUGIN_NAME="goapp"

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

resolve_go_module() {
  local package_path=$1
  local bitbucket_regex='(bitbucket.org/[^/]+/[^/]+)(:?/.*)?'
  local github_regex='(github.com/[^/]+/[^/]+)(:?/.*)?'
  local launchpad_regex='(launchpad.net/(:?~[^/]+/)?[^/]+(:?/[^/]+)?)(:?/.*)?'
  local jazz_regex='(hub.jazz.net/git/[^/]+/[^/]+)(:?/.*)?'

  log "Original package path $package_path"
  
  local module
  if [[ $package_path =~ $bitbucket_regex ]]; then
    module=${BASH_REMATCH[1]}
  elif [[ $package_path =~ $github_regex ]]; then
    module=${BASH_REMATCH[1]}
  elif [[ $package_path =~ $launchpad_regex ]]; then
    module=${BASH_REMATCH[1]}
  elif [[ $package_path =~ $jazz_regex ]]; then
    module=${BASH_REMATCH[1]}
  else
    log "None of the regexes matched to the package path, assuming module name equals package path"
    module=$package_path
  fi
  log "Resolved to $module"
  echo -n $module
}

add_plugin() {
  local asdf_plugins_dir="$1"
  local plugin_source_dir="$2"
  local plugin_name="$3"
  local go_package_path="$4"
  local go_module="$5"

  local install_path="$asdf_plugins_dir/$plugin_name"
  if [ -d $install_path ]; then
    fail "Plugin named $plugin_name is already added"
  fi
  
  (
    mkdir -p "$install_path/lib"
    for s in $(ls "$plugin_source_dir/lib"); do
      ln -s "$plugin_source_dir/lib/$s" "$install_path/lib"
    done
    ln -s "$plugin_source_dir/bin" "$install_path/bin"
    local plugin_config_file="$install_path/lib/plugin.config"
    echo "ASDF_GOAPP_PLUGIN_NAME=$plugin_name" > "$plugin_config_file"
    echo "ASDF_GOAPP_PACKAGE_PATH=$go_package_path" >> "$plugin_config_file"
    echo "ASDF_GOAPP_MODULE=$go_module" >> "$plugin_config_file"

    echo "Plugin $plugin_name added successfully!"
  ) || (
    # rm -rf "$install_path"
    fail "An error occurred while adding plugin $plugin_name."
  )
}

