#!/bin/sh

set -eu

FIX_FLAG=
case "${1:-}" in
	"")
		;;
	--fix)
		FIX_FLAG=--fix
		;;
	*)
		echo "Usage: $0 [--fix]" >&2
		exit 2
		;;
esac

if [ "$(uname -s)" = "Darwin" ]; then
	SDKROOT="$(xcrun --show-sdk-path)"
	find src -type f -name '*.cpp' -exec clang-tidy --quiet $FIX_FLAG -p . --extra-arg-before=-isysroot --extra-arg-before="$SDKROOT" {} \;
else
	find src -type f -name '*.cpp' -exec clang-tidy --quiet $FIX_FLAG -p . {} \;
fi