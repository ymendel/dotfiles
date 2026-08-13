#!/usr/bin/env bash
# a small but complete demo, for exercising an unattended run end to end
source "$DEMO_WRAPPER"

say "First, the orders that already exist" "There should be none yet"
hold
pe 'echo pretending to list orders'

say "Now one gets created"
hold
pei 'echo pretending to create one'

say "Every command above was pre-written"
demo_commands
