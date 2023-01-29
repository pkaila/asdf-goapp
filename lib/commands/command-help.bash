#!/usr/bin/env bash

set -euo pipefail

plugin_dir=$(dirname "$(dirname "$(dirname "$ASDF_CMD_FILE")")")
plugin_source_dir="$plugin_dir/lib/goapp-plugin"

# shellcheck source=../lib/utils.bash
source "${plugin_dir}/lib/utils.bash"

echo "The commands provided by the asdf goapp plugin provide a generic way to add"
echo "new asdf plugins for goapps. The way to do that is to use the asdf goapp add"
echo "command. For example to add a plugin for prototool, you would run:"
echo ""
echo "  asdf goapp add github.com/uber/prototool/cmd/prototool"
echo ""
echo "This would add a new plugin called goapp-prototool, which you could then use"
echo "to manage versions of prototool."
echo ""
print_usage
