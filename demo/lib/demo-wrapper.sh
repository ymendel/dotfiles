# demo-wrapper.sh — repairs and helpers for demo-magic.sh
#
# Source this from a demo script. It sources the vendored demo-magic in turn, so
# one line gets everything:
#
#     #!/usr/bin/env bash
#     source "$(demo-lib)"
#
#     say "First, the orders that already exist"
#     hold
#     pe 'http GET :3000/orders'
#
# Every demo-magic flag still works (-d no typing, -n no waiting, -c command
# numbers, -w N timeout), and --unattended runs the whole demo start to finish
# as a smoke test. See the README for explanation of why this exists.

__demo_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
__demo_topic_dir="$(cd "$__demo_lib_dir/.." && pwd -P)"

# our defaults. Precedence for each knob is flag, then environment, then this.
DEMO_TYPE_SPEED_DEFAULT=40
DEMO_PROMPT_TIMEOUT_DEFAULT=1
DEMO_PROMPT_DEFAULT='$ '

# demo-magic assigns TYPE_SPEED, PROMPT_TIMEOUT and DEMO_PROMPT unconditionally
# at source time, so anything already in the environment is gone by the time we
# get control back. Capture it first. The +set forms distinguish unset from set
# to the empty string, which for TYPE_SPEED means "no simulated typing".
__demo_env_type_speed="${TYPE_SPEED:-}"
__demo_env_type_speed_set="${TYPE_SPEED+set}"
__demo_env_prompt_timeout="${PROMPT_TIMEOUT:-}"
__demo_env_prompt_timeout_set="${PROMPT_TIMEOUT+set}"
__demo_env_demo_prompt="${DEMO_PROMPT:-}"
__demo_env_demo_prompt_set="${DEMO_PROMPT+set}"

# Build the argument list demo-magic should see: our own long flags taken out
# (its getopts would chew one a letter at a time), and -w noticed on the way
# past. -w N assigns PROMPT_TIMEOUT, whose demo-magic default is already 0, so
# once the source has run there is no telling -w0 from no flag at all. Bundled
# forms count: -dw5 as much as -w5 and -w 5.
DEMO_UNATTENDED="${DEMO_UNATTENDED:-false}"
__demo_prompt_timeout_flag=false
__demo_args=()
for __demo_arg in "$@"; do
    case $__demo_arg in
        --unattended) DEMO_UNATTENDED=true ;;
        --*) __demo_args+=("$__demo_arg") ;;
        -*w*)
            __demo_prompt_timeout_flag=true
            __demo_args+=("$__demo_arg")
            ;;
        *) __demo_args+=("$__demo_arg") ;;
    esac
done

# unattended means no typing and no pauses, which are demo-magic's own -d and
# -n. Injecting them rather than reimplementing keeps one code path.
if [[ $DEMO_UNATTENDED == true ]]; then
    __demo_args=(-d -n ${__demo_args[@]+"${__demo_args[@]}"})
fi

# demo-magic's -d handler unsets TYPE_SPEED, and a later line tests it with
# [[ -n "$TYPE_SPEED" ]] — an unbound reference that aborts the source under
# set -u, taking the documented -d flag with it. Relax nounset across the
# source and put it back after. nounset is a real `set -o` option name, so
# [[ -o nounset ]] works fine.
__demo_restore_nounset=false
if [[ -o nounset ]]; then
    __demo_restore_nounset=true
    set +u
fi
# Hand the filtered list to source rather than rewriting our caller's $@ with
# set --. Sourcing with arguments swaps them in for the duration and restores
# the caller's afterwards, so a demo script can still read its own arguments.
source "$__demo_topic_dir/vendor/demo-magic.sh" ${__demo_args[@]+"${__demo_args[@]}"}
if [[ $__demo_restore_nounset == true ]]; then
    set -u
fi

# Re-apply the three clobbered knobs, each conditional on whether a flag already
# spoke for it. Unconditional re-application here would silently discard the
# flag, which is the trap inside this fix.

# TYPE_SPEED unset now means -d was given (or --unattended injected it), so
# leave it alone. The flag is the highest priority.
if [[ -n "${TYPE_SPEED+set}" ]]; then
    if [[ -n $__demo_env_type_speed_set ]]; then
        TYPE_SPEED="$__demo_env_type_speed"
    else
        TYPE_SPEED="$DEMO_TYPE_SPEED_DEFAULT"
    fi
else
    # -d was given, and demo-magic implements that by unsetting the variable —
    # but its own p and pe go on to read it at *call* time, unguarded
    # (vendor/demo-magic.sh:107). Relaxing nounset across the source doesn't
    # reach that, so a strict-mode demo script survives the source and then
    # aborts on its first command. Bind it to the empty string: that is
    # precisely what the -z test there is looking for, so the flag keeps its
    # meaning and there is no longer an unbound reference to trip over.
    TYPE_SPEED=""
fi

if [[ $__demo_prompt_timeout_flag == false ]]; then
    if [[ -n $__demo_env_prompt_timeout_set ]]; then
        PROMPT_TIMEOUT="$__demo_env_prompt_timeout"
    else
        PROMPT_TIMEOUT="$DEMO_PROMPT_TIMEOUT_DEFAULT"
    fi
fi

# DEMO_PROMPT has no flag, so environment-or-default is the whole precedence.
if [[ -n $__demo_env_demo_prompt_set ]]; then
    DEMO_PROMPT="$__demo_env_demo_prompt"
else
    DEMO_PROMPT="$DEMO_PROMPT_DEFAULT"
fi

# demo-magic wraps every command in `stty -echoctl` / `stty echoctl`, to keep a
# ^C from echoing. Both fail with "stdin isn't a terminal" when stdin is closed
# (which is how an unattended run keeps the pauses from blocking). That means a
# run whose entire job is to surface real errors instead burries them in a mass
# of stderr lines (two per command). So only set the terminal when there is, in
# fact, a terminal to set.
#
# This is really just upstream's `run_cmd` copied here, with the `stty` calls
# wrapped in `[[ -t 0 ]]` checks.
run_cmd () {
    handle_cancel () {
        printf ""
    }

    trap handle_cancel SIGINT
    if [[ -t 0 ]]; then
        stty -echoctl
    fi
    eval $@
    if [[ -t 0 ]]; then
        stty echoctl
    fi
    trap - SIGINT
}

DEMO_SAY_COLOR="${DEMO_SAY_COLOR:-$GREY}"

# A narration block above a command, one argument per line. The blank line
# separating it from the previous command's output is printed once, ahead of the
# first line — a per-line newline would open a gap inside the block too.
say () {
    printf '\n'
    local line
    for line in "$@"; do
        printf '%b%s%b\n' "$DEMO_SAY_COLOR" "$line" "$COLOR_RESET"
    done
}

# demo-magic's own wait, used inside pe, is bounded by PROMPT_TIMEOUT.
# That works for a pause between typing a command and executing it, but
# there are times you want a completely manual and explicit "wait until
# I say go". Use `hold` for that.
#
# When the pause prints nothing, it can look as if the demo has hung.
# Letting `hold` animate a hint fixes that issue. The hint is on its
# own line, and it gets wiped before the next command.
#
# Each animation "frame set" is defined here, with a list of frames and
# an interval. Note that the frames don't _have_ to be the same width,
# but staying the same width keeps the hint in place. So do that.
# The interval is set explicitly because what feels right can depend
# on more than simple frame information — like it could be about the
# difference between frames, not just the number of frames.

# Add a new "frame set" choice by defining two variables here:
# - DEMO_HOLD_FRAMES_<name>   = an array of strings to rotate through
# - DEMO_HOLD_INTERVAL_<name> = a (floating-point) number of seconds to wait between frames

DEMO_HOLD_FRAMES_MARQUEE=('·  ' '·· ' '···' ' ··' '  ·' '   ')  # dots sweeping across
DEMO_HOLD_INTERVAL_MARQUEE=0.15

DEMO_HOLD_FRAMES_BREATHE=('▪  ' '▪▪ ' '▪▪▪' '▪▪ ')             # a bar expanding and contracting
DEMO_HOLD_INTERVAL_BREATHE=0.2

DEMO_HOLD_FRAMES_CARET=('▸' '▹')                                # a caret blinking
DEMO_HOLD_INTERVAL_CARET=0.45

DEMO_HOLD_FRAMES_ELLIPSIS=('   ' '.  ' '.. ' '...')             # ASCII only, nothing to render wrong
DEMO_HOLD_INTERVAL_ELLIPSIS=0.20

DEMO_HOLD_FRAMES_SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')  # familiar, but reads as "busy" rather than "your turn"
DEMO_HOLD_INTERVAL_SPINNER=0.10

# Which set to animate: any name above with the DEMO_HOLD_FRAMES_ prefix
# dropped, so `DEMO_HOLD_FRAMES=CARET ./demo.sh` switches for one run.
DEMO_HOLD_FRAMES="${DEMO_HOLD_FRAMES:-MARQUEE}"
DEMO_HOLD_HINT="${DEMO_HOLD_HINT:-ENTER}"
DEMO_HOLD_COLOR="${DEMO_HOLD_COLOR:-$GREY}"

# DEMO_HOLD_INTERVAL is deliberately *not* given a default here. Leaving it
# unset is what lets the chosen set's own interval apply.
# It can be overridden at the command line if you don't want to use the set's
# defined interval.

# Runs in the background while hold blocks on read. Cleanup lives in the trap
# rather than in hold, so `wait` guarantees the line is wiped before the next
# command prints, and so a ^C through the demo can't leave the cursor hidden.
__demo_hold_animate () {
    trap 'printf "\r\033[K\033[?25h"; exit 0' TERM INT

    # array has to be set by nameref
    local -n frames="DEMO_HOLD_FRAMES_$DEMO_HOLD_FRAMES"
    local per_set="DEMO_HOLD_INTERVAL_$DEMO_HOLD_FRAMES"
    local interval="${DEMO_HOLD_INTERVAL:-${!per_set:-0.15}}"

    local i=0
    printf '\033[?25l'
    while :; do
        printf '\r%b%s %s%b\033[K' "$DEMO_HOLD_COLOR" "${frames[i]}" \
            "$DEMO_HOLD_HINT" "$COLOR_RESET"
        # post-increment with (( )) returns 1 when i is 0
        # under set -e, that would kill the animator
        i=$(( (i + 1) % ${#frames[@]} ))
        # Backgrounding the sleep is what keeps the trap prompt: bash runs a
        # trap while blocked in wait, but not while blocked in a foreground
        # sleep — which would hold the wipe for a whole interval after ENTER.
        sleep "$interval" &
        builtin wait $! 2>/dev/null || true
    done
}

# Note that because demo-magic has a function named `wait`, every wait-on-process
# call has to be `builtin wait`
# See above, and at the end of `hold`

hold () {
    if [[ $DEMO_UNATTENDED == true ]]; then
        return 0
    fi
    # check for a terminal on both ends
    # It's not enough to check --unattended, because output can be directed separately
    if [[ ! -t 0 || ! -t 1 ]]; then
        read -rs
        return 0
    fi

    # The actual animator runs in the background, which means any errors there
    # aren't shown. Check for the animation info here first, and if it's wrong
    # just warn and go with the default. Otherwise, the animation would be
    # an empty frame set, and modulus of 0.
    local named="DEMO_HOLD_FRAMES_$DEMO_HOLD_FRAMES"
    if [[ -z ${!named+set} ]]; then
        printf 'hold: no frame set named %s, falling back to MARQUEE\n' \
            "$DEMO_HOLD_FRAMES" >&2
        DEMO_HOLD_FRAMES=MARQUEE
    fi

    __demo_hold_animate &
    local animator=$!
    read -rs
    # Both guarded: the animator may already be gone, and a kill that lands
    # before the trap installs makes wait report 143. Neither should abort a
    # demo running under set -e.
    kill "$animator" 2>/dev/null || true
    builtin wait "$animator" 2>/dev/null || true
}

# The demo's commands with the pe wrapper stripped off, which can be useful
# for a sort of "every one of those was pre-written, I only pressed ENTER"
# flourish at the end. This is written as a function because it's incredibly
# ugly and fiddly to do as an inline pipeline (let me just say `'"'"'`).
demo_commands () {
    local script="${1:-$0}"
    sed -nE "s/^[[:space:]]*pei?[[:space:]]*'(.*)'[[:space:]]*\$/\1/p" "$script"
}

# An unattended run reads stdin from /dev/null so the pauses don't block, and
# httpie then treats that as a request body and refuses to combine it with
# key=value items. Only the data-carrying calls fail, which can feel inconsistent
# enough that you may think it's the demo that's broken, rather than the tooling.
# --ignore-stdin fixes it, and using the config dir means it doesn't have to be added
# to every command.
if [[ $DEMO_UNATTENDED == true ]]; then
    export HTTPIE_CONFIG_DIR="$__demo_topic_dir/httpie-unattended"
fi

unset __demo_lib_dir __demo_topic_dir __demo_arg __demo_args \
    __demo_env_type_speed __demo_env_type_speed_set \
    __demo_env_prompt_timeout __demo_env_prompt_timeout_set \
    __demo_env_demo_prompt __demo_env_demo_prompt_set \
    __demo_prompt_timeout_flag __demo_restore_nounset
