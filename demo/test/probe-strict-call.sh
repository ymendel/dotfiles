#!/usr/bin/env bash
# the second half of the set -u repair: surviving the *source* is not enough,
# because demo-magic's p and pe read TYPE_SPEED again at call time
set -euo pipefail
source "$DEMO_WRAPPER" --unattended
pe 'echo strict-call-survived'
