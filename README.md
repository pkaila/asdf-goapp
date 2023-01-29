<div align="center">

# asdf-goapp [![Build](https://github.com/pkaila/asdf-goapp/actions/workflows/build.yml/badge.svg)](https://github.com/pkaila/asdf-goapp/actions/workflows/build.yml) [![Lint](https://github.com/pkaila/asdf-goapp/actions/workflows/lint.yml/badge.svg)](https://github.com/pkaila/asdf-goapp/actions/workflows/lint.yml)

A generic "goapp" plugin for the [asdf version manager](https://asdf-vm.com). A "goapp" in this case is any CLI tool written in Go, which can be installed with go install.

This plugin does not itself install any goapps, but adds a new command to asdf for adding new goapp plugins
for managing the versions of the given goapp. The reason for this slightly convoluted usage is that
adding a generic goapp requires more information than just a name of a plugin. See the [usage](#usage) -section
for more information.

The plugin is inspired by and borrows some of the code from the excellent
[pyapp plugin](https://github.com/amrox/asdf-pyapp) by [Andy Mroczkowski](https://github.com/amrox/).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`: generic POSIX utilities.
- `go`: for installing the goapps
  - Version >= 1.16 found in the path OR
  - [asdf-golang](https://github.com/kennyp/asdf-golang) plugin

# Install

Plugin:

```shell
asdf plugin add goapp https://github.com/pkaila/asdf-goapp.git
```
# Usage

Add a goapp-\<tool\> plugin:

```shell
# Add goapp-<tool> plugin`
asdf goapp add github.com/user/project/dir/<tool>

# For example add a plugin for prototool
asdf goapp add github.com/uber/prototool/cmd/prototool

# For more help run "asdf goapp help"
asdf goapp help
```

Now you can interact with the goapp-\<tool\> plugin as with any other asdf plugin:

```shell
# Show all installable versions
asdf list-all goapp-<tool>

# Install specific version
asdf install goapp-<tool> latest

# Set a version globally (on your ~/.tool-versions file)
asdf global goapp-<tool> latest

# Now <tool> commands are available
<tool> version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/pkaila/asdf-goapp/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Pauli Kaila](https://github.com/pkaila/)
