#!/usr/bin/env bash
#
# Does every route into the lazy loader actually work, in a shell that loaded
# the real dotfiles? Three routes to cover:
#
#   compat  — Homebrew's own file, found through the install.sh symlink
#   shim    — a tracked one-liner in shell/bash-completion/completions
#   lazy    — a formula that installs into share/bash-completion/completions
#
# Reports the *source* of each, so a pass through the wrong route still shows.
# The commands it checks are whatever this machine happens to have installed, so
# SKIP is a normal result elsewhere and the list is meant to be edited.
# Read-only.
#
# Everything below goes in as a single-quoted -c argument, so it can't contain an
# apostrophe. A quoted heredoc on stdin would lift that, and it's been tried: an
# interactive shell reading stdin prints the prompt before every line it consumes,
# which took the run from 1.4s to 10.6s and buried the ten result lines in prompt
# escapes, continuation markers and a trailing `logout`. If the constraint ever
# starts to grate, the way out is to move the body into its own file — not named
# *.bash, or bashrc.symlink will source it at startup — and source that from -c.
set -uo pipefail

bash -lic '
    check () {  # check <command> <route>
        local cmd="$1" route="$2"

        if ! command -v "$cmd" > /dev/null 2>&1
        then
            printf "  %-8s %-8s SKIP (no such command here)\n" "$cmd" "$route"
            return
        fi

        # -D means nothing is registered yet, which is the point of lazy
        if complete -p "$cmd" > /dev/null 2>&1
        then
            printf "  %-8s %-8s EAGER (registered before any tab)\n" "$cmd" "$route"
            return
        fi

        if _comp_load -- "$cmd" > /dev/null 2>&1 && complete -p "$cmd" > /dev/null 2>&1
        then
            printf "  %-8s %-8s ok\n" "$cmd" "$route"
        else
            printf "  %-8s %-8s LOST\n" "$cmd" "$route"
        fi
    }

    printf "bash-completion %s, compat dir %s\n\n" \
        "${BASH_COMPLETION_VERSINFO[*]:-<not loaded>}" \
        "${BASH_COMPLETION_COMPAT_DIR:-<default>}"

    check gdal   compat
    check brew   compat
    check bat    compat

    # heroku used to report LOST on this route, and did so on the eager path too:
    # its compat file only sources a cache under ~/Library that names a heroku
    # that is no longer installed. It has a shim of its own now, sourcing the
    # completion function directly, so it should pass as one.
    check heroku shim
    check stripe shim
    check adr    shim
    # These three have shims that never get reached, so EAGER is the expected
    # result and not a regression: ~/.local/bashrc sources the completion.bash.inc
    # out of a google-cloud-sdk in ~/Downloads, which registers all three while
    # the shell is starting. That is the last eager completion load left here.
    check gcloud shim
    check bq     shim
    check gsutil shim
    check git    lazy
' 2>&1 | grep -v 'job control\|terminal process group'
