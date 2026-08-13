#!/usr/bin/env bash
#
# Checks the demo wrapper's repairs. Run it after bumping vendor/demo-magic.sh,
# or after touching lib/demo-wrapper.sh:
#
#     demo/test/run-checks.sh
#
# Deliberately not set -e: a failing check should report, not abort the run.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
topic="$(cd "$here/.." && pwd -P)"
export DEMO_WRAPPER="$topic/lib/demo-wrapper.sh"
config_dir="$topic/httpie-unattended"
probe="$here/probe-knobs.sh"

# clear the three knobs once, here, rather than per call — a per-call `env -u`
# would also strip whatever a given check is deliberately setting
unset TYPE_SPEED PROMPT_TIMEOUT DEMO_PROMPT

pass=0
fail=0

check () {  # check <label> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
        printf '  PASS  %-44s %s\n' "$1" "$3"
        pass=$((pass + 1))
    else
        printf '  FAIL  %-44s expected [%s] got [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

# Each probe runs as its own process with its environment named explicitly, so
# nothing leaks between checks — a prefix assignment on a *function* call can
# persist after the function returns. Output is TYPE_SPEED|PROMPT_TIMEOUT|DEMO_PROMPT.

echo "== precedence: nothing set, so the wrapper's defaults"
check "no flags, no env" '40|1|$ ' "$(bash "$probe" < /dev/null)"

echo "== precedence: environment beats the wrapper default"
check "TYPE_SPEED=99 in env" '99|1|$ ' \
    "$(env TYPE_SPEED=99 bash "$probe" < /dev/null)"
check "PROMPT_TIMEOUT=7 in env" '40|7|$ ' \
    "$(env PROMPT_TIMEOUT=7 bash "$probe" < /dev/null)"
check "DEMO_PROMPT='> ' in env" '40|1|> ' \
    "$(env DEMO_PROMPT='> ' bash "$probe" < /dev/null)"
check "TYPE_SPEED= (set but empty)" '|1|$ ' \
    "$(env TYPE_SPEED= bash "$probe" < /dev/null)"

echo "== precedence: flag beats environment (the trap inside the fix)"
check "-d" 'UNSET|1|$ ' "$(bash "$probe" -d < /dev/null)"
check "-d with TYPE_SPEED=99 in env" 'UNSET|1|$ ' \
    "$(env TYPE_SPEED=99 bash "$probe" -d < /dev/null)"
check "-w5" '40|5|$ ' "$(bash "$probe" -w5 < /dev/null)"
check "-w 5 (separate arg)" '40|5|$ ' "$(bash "$probe" -w 5 < /dev/null)"
check "-w5 with PROMPT_TIMEOUT=7 in env" '40|5|$ ' \
    "$(env PROMPT_TIMEOUT=7 bash "$probe" -w5 < /dev/null)"
check "-w0 vs no flag at all" '40|0|$ ' "$(bash "$probe" -w0 < /dev/null)"
check "-w0 with PROMPT_TIMEOUT=7 in env" '40|0|$ ' \
    "$(env PROMPT_TIMEOUT=7 bash "$probe" -w0 < /dev/null)"
check "-dw5 (bundled)" 'UNSET|5|$ ' "$(bash "$probe" -dw5 < /dev/null)"

echo "== --unattended implies -d -n, and is stripped before getopts"
check "--unattended" 'UNSET|1|$ ' "$(bash "$probe" --unattended < /dev/null)"
check "DEMO_UNATTENDED=true in env" 'UNSET|1|$ ' \
    "$(env DEMO_UNATTENDED=true bash "$probe" < /dev/null)"
check "--unattended -w5 together" 'UNSET|5|$ ' \
    "$(bash "$probe" --unattended -w5 < /dev/null)"

echo "== set -u repair: -d survives strict mode, nounset comes back"
check "strict mode plus -d" 'UNSET|nounset-restored:yes' \
    "$(bash "$here/probe-strict.sh" -d < /dev/null 2>&1)"

echo "== demo-lib resolves to the wrapper"
check "demo-lib output" "$DEMO_WRAPPER" "$("$topic/bin/demo-lib")"

echo "== sourcing the wrapper leaves the demo script's own arguments alone"
check "caller keeps every argument it was given" 'caller args: [--unattended -w5 extra]' \
    "$(bash "$here/probe-args.sh" --unattended -w5 extra < /dev/null)"
check "caller with no arguments stays empty" 'caller args: []' \
    "$(bash "$here/probe-args.sh" < /dev/null)"

echo "== unattended end-to-end run completes without blocking"
demo_out="$(bash "$here/probe-demo.sh" --unattended < /dev/null 2>&1)"
demo_status=$?
check "exit status" "0" "$demo_status"
for wanted in "pretending to list orders" "pretending to create one" "There should be none yet"; do
    if [[ $demo_out == *"$wanted"* ]]; then found=yes; else found=no; fi
    check "output contains: $wanted" "yes" "$found"
done
check "demo_commands stripped the wrapper" "echo pretending to list orders" \
    "$(printf '%s\n' "$demo_out" | grep -m1 '^echo pretending to list orders')"
check "demo_commands caught the pei call too" "echo pretending to create one" \
    "$(printf '%s\n' "$demo_out" | grep -m1 '^echo pretending to create one')"

echo "== run_cmd repair: no stty complaints when stdin is not a terminal"
if [[ $demo_out == *"stty"* ]]; then noisy=yes; else noisy=no; fi
check "stty noise in unattended output" "no" "$noisy"

echo "== httpie stdin trap, both directions"
without="$(http --offline POST example.test/orders customer=alice < /dev/null 2>&1)"
if [[ $without == *"cannot be mixed"* ]]; then refused=yes; else refused=no; fi
check "no config: refuses to mix stdin and key=value" "yes" "$refused"
with="$(HTTPIE_CONFIG_DIR="$config_dir" http --offline POST example.test/orders customer=alice < /dev/null 2>&1)"
check "with config: builds the body" '{"customer": "alice"}' \
    "$(printf '%s\n' "$with" | tail -1)"

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
