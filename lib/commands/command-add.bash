#!/usr/bin/env bash

set -euo pipefail

plugin_dir=$(dirname "$(dirname "$(dirname "$ASDF_CMD_FILE")")")
plugin_source_dir="$plugin_dir/lib/goapp-plugin"
plugins_dir="$(dirname "$plugin_dir")"

# shellcheck source=../lib/utils.bash
source "${plugin_dir}/lib/utils.bash"

if [ "$#" -eq 1 ]; then
  plugin_name="${1##*/}"
  package_path="$1"
elif [ "$#" -eq 2 ]; then
  plugin_name="$1"
  package_path="$2"
else
  echo "Usage: asdf goapp add [<plugin_name>] <package_path>"
  echo "    plugin_name: The name you want to give for the plugin"
  echo "    package_path: The path for the go package to install when installing with the plugin"
  exit 1
fi

plugin_name="goapp-${plugin_name}"
module_name="$(resolve_go_module "$package_path")"

echo "Adding Go package ${package_path} from module $module_name as ASDF plugin ${plugin_name}"
log "Plugins dir: $plugins_dir, plugin source dir: $plugin_source_dir"
add_plugin "$plugins_dir" "$plugin_source_dir" "$plugin_name" "$package_path" "$module_name"
