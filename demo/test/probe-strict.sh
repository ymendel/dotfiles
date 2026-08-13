#!/usr/bin/env bash
# the case that breaks unrepaired demo-magic: strict mode plus -d
set -euo pipefail
source "$DEMO_WRAPPER"
if [[ -o nounset ]]; then
    restored=yes
else
    restored=no
fi
printf '%s|nounset-restored:%s\n' "${TYPE_SPEED-UNSET}" "$restored"
