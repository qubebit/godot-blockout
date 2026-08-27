#!/bin/sh

set -eu

if [ "$(uname -s)" = "Darwin" ]; then
	ARCH="$(uname -m)"
	exec scons compiledb=yes platform=macos arch="$ARCH" compile_commands.json
else
	exec scons compiledb=yes compile_commands.json
fi