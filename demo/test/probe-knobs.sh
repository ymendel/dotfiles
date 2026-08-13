#!/usr/bin/env bash
# stands in for a demo script: sources the wrapper with no args, so the wrapper
# sees this script's own positional parameters, exactly as a real demo does
source "$DEMO_WRAPPER"
printf '%s|%s|%s\n' "${TYPE_SPEED-UNSET}" "${PROMPT_TIMEOUT-UNSET}" "${DEMO_PROMPT-UNSET}"
