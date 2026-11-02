#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/checks
swiftc -D DEBUG Sources/Rightnest/ControlPanel.swift Sources/Rightnest/Localization.swift Checks/HoverChecks/main.swift -o .build/checks/HoverChecks
.build/checks/HoverChecks
