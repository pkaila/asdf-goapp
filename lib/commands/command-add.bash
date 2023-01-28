#!/usr/bin/env bash

set -euo pipefail

plugin_dir=$(dirname "$(dirname "$(dirname "$ASDF_CMD_FILE")")")
plugin_source_dir="$plugin_dir/lib/goapp-plugin"
plugins_dir="$(dirname "$plugin_dir")"

# shellcheck source=../lib/utils.bash
source "${plugin_dir}/lib/utils.bash"

local plugin_name package_path module_name

if [ "$#" -eq 1 ]; then
  plugin_name="${1##*/}"
  package_path="$1"
elif [ "$#" -eq 2 ]; then
  plugin_name="$1"
  package_path="$2"
elif [ "$#" -eq 3 ]; then
  plugin_name="$1"
  package_path="$2"
  module_name="$3"
else
  echo "Usage:"
  echo "  asdf goapp add [<plugin_name>] <package_path>"
  echo "  asdf goapp add <plugin_name> <package_path> <module_name>"
  echo ""
  echo "Arguments:"
  echo "  plugin_name:  The name you want to give for the plugin, if not given the last"
  echo "                part of the package_path will be used. The name is always"
  echo "                prepended with 'goapp-'."
  echo "  package_path: The path for the go package to install when installing with the"
  echo "                plugin."
  echo "  module_name:  Override the Go module name if the plugin does not use the"
  echo "                correct one automatically."
  exit 1
fi

plugin_name="goapp-${plugin_name}"
if test -n ${module_name+x}; then
  module_name="$(resolve_go_module "$package_path")"
fi

echo "Adding a new goapp plugin:"
echo "  Plugin name: $plugin_name"
echo "  Go package path: $package_path"
echo "  Go module name: $module_name"
log "Plugins dir: $plugins_dir, plugin source dir: $plugin_source_dir"
add_plugin "$plugins_dir" "$plugin_source_dir" "$plugin_name" "$package_path" "$module_name"
