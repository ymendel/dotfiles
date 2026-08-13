#!/usr/bin/env bash
# a demo script's own arguments must survive sourcing the wrapper — the wrapper
# hands its filtered list to source rather than rewriting $@ with set --
source "$DEMO_WRAPPER"
printf 'caller args: [%s]\n' "$*"
