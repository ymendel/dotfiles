#!/usr/bin/env bash
#
# Checks link_tree, the nested-config linking used for anything wanting a path
# instead of a $HOME dotfile:
#
#     script/test/run-checks.sh
#
# Builds a fake DOTFILES_ROOT rather than running bootstrap, which would try to
# chsh and install packages.
#
# Two callers link config trees — script/bootstrap and system/install.sh — so
# some of this checks that both of them still hold up their end, which no
# runtime check here would catch: this file sources the helpers itself, so it
# can't notice a caller that forgot to.
#
# Deliberately not set -e: a failing check should report, not abort the run.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
scriptdir="$(cd "$here/.." && pwd -P)"
repo="$(cd "$scriptdir/.." && pwd -P)"

source "$scriptdir/helpers/printing.sh"
source "$scriptdir/helpers/filestuff.sh"
source "$scriptdir/helpers/linking.sh"

pass=0
fail=0

check () {  # check <label> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
        printf '  PASS  %-46s %s\n' "$1" "$3"
        pass=$((pass + 1))
    else
        printf '  FAIL  %-46s expected [%s] got [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

target () {  # target <path> — where a link points, or a word saying it isn't one
    if [[ -L "$1" ]]; then
        readlink "$1"
    elif [[ -e "$1" ]]; then
        echo "NOT-A-LINK"
    else
        echo "ABSENT"
    fi
}

mentions () {  # mentions <file> <pattern> — yes/no, for the caller contracts
    if grep -q "$2" "$1"; then echo yes; else echo no; fi
}

sourced_config_home () {  # what CONFIG_HOME comes out as, in a fresh subshell
    ( source "$scriptdir/helpers/filestuff.sh"; echo "$CONFIG_HOME" )
}

# link_tree reads DOTFILES_ROOT and the three flags link_file wants, exactly as
# install_dotfiles and system/install.sh's link_dotfiles both provide them.
DOTFILES_ROOT="$(mktemp -d)"
dest="$(mktemp -d)"
overwrite_all=false backup_all=false skip_all=false

mkdir -p "$DOTFILES_ROOT/editing/config/zed"
printf '{}\n' > "$DOTFILES_ROOT/editing/config/zed/settings.json"

mkdir -p "$DOTFILES_ROOT/shell/config/deep/deeper"
printf 'x\n' > "$DOTFILES_ROOT/shell/config/deep/deeper/thing.conf"

mkdir -p "$DOTFILES_ROOT/db/config"
printf 'y\n' > "$DOTFILES_ROOT/db/config/flat.conf"

mkdir -p "$DOTFILES_ROOT/ruby/bin"
printf 'z\n' > "$DOTFILES_ROOT/ruby/bin/tool"

mkdir -p "$DOTFILES_ROOT/.hidden/config"
printf 'w\n' > "$DOTFILES_ROOT/.hidden/config/secret.conf"

# Subshell so printing.sh's `fail` (which exits) can't take the harness with it,
# and /dev/null on stdin so an unexpected link_file prompt can't hang.
run () { ( link_tree config "$dest" ) >/dev/null 2>&1 </dev/null; }

run

echo "== the path below config/ is what gets preserved"
check "nested file" "$DOTFILES_ROOT/editing/config/zed/settings.json" \
    "$(target "$dest/zed/settings.json")"
check "several levels deep" "$DOTFILES_ROOT/shell/config/deep/deeper/thing.conf" \
    "$(target "$dest/deep/deeper/thing.conf")"
check "flat file, no nesting" "$DOTFILES_ROOT/db/config/flat.conf" \
    "$(target "$dest/flat.conf")"

echo "== the intervening directories are real, not linked"
check "dest dir exists" "yes" "$([[ -d $dest/zed ]] && echo yes || echo no)"
check "dest dir is not itself a link" "yes" \
    "$([[ ! -L $dest/zed ]] && echo yes || echo no)"

echo "== what must be left alone"
check "a topic with no config/ dir" "ABSENT" "$(target "$dest/tool")"
check "a dotted dir is never traversed" "ABSENT" "$(target "$dest/secret.conf")"
check "nothing else got linked" "3" "$(find "$dest" -type l | wc -l | tr -d ' ')"

echo "== bootstrap is meant to be safe to re-run"
run
check "same link after a second run" "$DOTFILES_ROOT/editing/config/zed/settings.json" \
    "$(target "$dest/zed/settings.json")"
check "no duplicates, no backups" "3" "$(find "$dest" -type l | wc -l | tr -d ' ')"
check "no .backup left behind" "0" \
    "$(find "$dest" -name '*.backup' | wc -l | tr -d ' ')"

echo "== CONFIG_HOME, the root both callers link into"
check "defaults to ~/.config" "$HOME/.config" \
    "$(unset XDG_CONFIG_HOME; sourced_config_home)"
check "honors XDG_CONFIG_HOME when set" "/tmp/xdg-somewhere-else" \
    "$(XDG_CONFIG_HOME=/tmp/xdg-somewhere-else; sourced_config_home)"

# An empty root would build paths from / rather than failing, so the thing worth
# guarding is that every caller has CONFIG_HOME in scope at all — which means
# sourcing filestuff.sh, where ensure_dir lives too.
echo "== both callers hold up link_tree's end of the deal"
check "bootstrap sources filestuff" "yes" \
    "$(mentions "$repo/script/bootstrap" 'helpers/filestuff.sh')"
check "system/install.sh sources filestuff" "yes" \
    "$(mentions "$repo/system/install.sh" 'helpers/filestuff.sh')"
check "bootstrap links config trees" "yes" \
    "$(mentions "$repo/script/bootstrap" 'link_tree config')"
check "system/install.sh links config trees" "yes" \
    "$(mentions "$repo/system/install.sh" 'link_tree config')"

rm -rf "$DOTFILES_ROOT" "$dest"

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
