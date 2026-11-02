#!/bin/zsh
set -eu
cd "${0:A:h:h}"
swift build --product RightSideProbe
"$(swift build --show-bin-path)/RightSideProbe" "$@"
