#!/usr/bin/env bash
#
# Checks the linking helpers: link_tree, which puts a topic's config/ tree at a
# nested path, and link_dotfiles, which does that plus the *.symlink files:
#
#     script/test/run-checks.sh
#
# Run it under both bashes. bootstrap does its linking before it installs
# Homebrew, so these helpers have to work on the macOS 3.2 as well as on the 5.x
# that `env bash` finds once Homebrew is there — which rules out `mapfile` and
# anything else post-3.2:
#
#     bash script/test/run-checks.sh
#     /bin/bash script/test/run-checks.sh
#
# Builds a fake DOTFILES_ROOT rather than running bootstrap, which would try to
# chsh and install packages. link_dotfiles reads $HOME and CONFIG_HOME as well,
# so those get redirected too — getting that wrong would link into the real home
# directory.
#
# Two callers do the linking — script/bootstrap and system/install.sh — so some
# of this checks that both still go through the shared helper, which no runtime
# check here would catch: this file sources the helpers itself, so it can't
# notice a caller that forgot to.
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

# What a moved config file leaves behind: the previous run's link, still pointing
# at the old path. `-e` follows it and calls it absent, so link_file used to skip
# its existence check entirely and then fail on `ln -s`. Own dest dir, so the
# link counts above stay about what they were written for.
echo "== a link left dangling by a move gets repaired"
moved="$(mktemp -d)"
mkdir -p "$DOTFILES_ROOT/vcs/config"
printf 'v\n' > "$DOTFILES_ROOT/vcs/config/tool.conf"
ln -s "$DOTFILES_ROOT/vcs/moved-away.conf" "$moved/tool.conf"

check "the fixture is a link that resolves to nothing" "yes" \
    "$([[ -L $moved/tool.conf && ! -e $moved/tool.conf ]] && echo yes || echo no)"

( link_tree config "$moved" ) >/dev/null 2>&1 </dev/null

check "relinked to where the file lives now" "$DOTFILES_ROOT/vcs/config/tool.conf" \
    "$(target "$moved/tool.conf")"
check "the dead link was not backed up" "0" \
    "$(find "$moved" -name '*.backup' | wc -l | tr -d ' ')"

# link_file asks its question on stdin, so the file list must not arrive there
# too. link_tree used to feed the loop from `< <(find ...)`, whose redirect
# covers the body — the prompt then read the drained find output and saw EOF,
# so no answer could ever be given. Only zed/settings.json exists at these
# destinations, so it is the one file that prompts and the one answer is its.
echo "== an answer given at the prompt actually lands"
overwritten="$(mktemp -d)"
mkdir -p "$overwritten/zed"
printf 'PRE-EXISTING\n' > "$overwritten/zed/settings.json"
printf 'o' | ( link_tree config "$overwritten" ) >/dev/null 2>&1

check "[o]verwrite replaced the file with the link" \
    "$DOTFILES_ROOT/editing/config/zed/settings.json" \
    "$(target "$overwritten/zed/settings.json")"

preserved="$(mktemp -d)"
mkdir -p "$preserved/zed"
printf 'PRE-EXISTING\n' > "$preserved/zed/settings.json"
printf 'b' | ( link_tree config "$preserved" ) >/dev/null 2>&1

check "[b]ackup linked over it" "$DOTFILES_ROOT/editing/config/zed/settings.json" \
    "$(target "$preserved/zed/settings.json")"
check "[b]ackup kept the original" "1" \
    "$(find "$preserved" -name '*.backup' | wc -l | tr -d ' ')"

# `set -e` on purpose here: it is what both real callers run under, and it is
# what turns an unguarded `read` at EOF into an abort with nothing printed.
echo "== a prompt with nobody to answer it fails out loud"
unanswered="$(mktemp -d)"
mkdir -p "$unanswered/zed"
printf 'PRE-EXISTING\n' > "$unanswered/zed/settings.json"
eof_output="$( ( set -e; link_tree config "$unanswered" ) 2>&1 </dev/null )"

check "it says which link it could not make" "yes" \
    "$([[ "$eof_output" == *"couldn't link"* ]] && echo yes || echo no)"
check "and it left the existing file alone" "NOT-A-LINK" \
    "$(target "$unanswered/zed/settings.json")"

mkdir -p "$DOTFILES_ROOT/git"
printf 'a\n' > "$DOTFILES_ROOT/git/gitconfig.symlink"

mkdir -p "$DOTFILES_ROOT/shell"
printf 'b\n' > "$DOTFILES_ROOT/shell/tmux.conf.symlink"

mkdir -p "$DOTFILES_ROOT/media/cam"
printf 'c\n' > "$DOTFILES_ROOT/media/cam/buried.symlink"

fake_home="$(mktemp -d)"
fake_config="$(mktemp -d)"

# Both $HOME and CONFIG_HOME redirected, per the note at the top of the file.
run_dotfiles () {
    ( HOME="$fake_home"; CONFIG_HOME="$fake_config"; link_dotfiles ) \
        >/dev/null 2>&1 </dev/null
}

run_dotfiles

echo "== link_dotfiles puts *.symlink files in \$HOME behind a dot"
check "plain name" "$DOTFILES_ROOT/git/gitconfig.symlink" \
    "$(target "$fake_home/.gitconfig")"
check "name carrying its own dots" "$DOTFILES_ROOT/shell/tmux.conf.symlink" \
    "$(target "$fake_home/.tmux.conf")"
check "nesting flattens to the basename" "$DOTFILES_ROOT/media/cam/buried.symlink" \
    "$(target "$fake_home/.buried")"

echo "== link_dotfiles covers the config trees in the same pass"
check "config tree came along" "$DOTFILES_ROOT/editing/config/zed/settings.json" \
    "$(target "$fake_config/zed/settings.json")"
check "and nothing landed outside the two fake roots" "3" \
    "$(find "$fake_home" -type l | wc -l | tr -d ' ')"

echo "== CONFIG_HOME, the root both callers link into"
check "defaults to ~/.config" "$HOME/.config" \
    "$(unset XDG_CONFIG_HOME; sourced_config_home)"
check "honors XDG_CONFIG_HOME when set" "/tmp/xdg-somewhere-else" \
    "$(XDG_CONFIG_HOME=/tmp/xdg-somewhere-else; sourced_config_home)"

# An empty root would build paths from / rather than failing, so the thing worth
# guarding is that every caller has CONFIG_HOME in scope at all — which means
# sourcing filestuff.sh, where ensure_dir lives too.
echo "== both callers hold up the helpers' end of the deal"
check "bootstrap sources filestuff" "yes" \
    "$(mentions "$repo/script/bootstrap" 'helpers/filestuff.sh')"
check "system/install.sh sources filestuff" "yes" \
    "$(mentions "$repo/system/install.sh" 'helpers/filestuff.sh')"

# script/install runs each installer from inside a loop, and an installer can ask
# a question — linking does. Running script/install for real here would install
# packages, so this guards the shape instead: the list comes off fd 3, which is
# what leaves stdin free for the installer to read from.
echo "== the installer loop leaves stdin free"
check "script/install reads its list on fd 3" "yes" \
    "$(mentions "$repo/script/install" 'read -r installer <&3')"
check "and fills fd 3 rather than stdin" "yes" \
    "$(mentions "$repo/script/install" 'done 3< <(find')"

# The loop used to be copied into both callers. Guard against it coming back.
echo "== the linking itself lives in one place"
check "the helper links config trees" "yes" \
    "$(mentions "$scriptdir/helpers/linking.sh" 'link_tree config')"
check "bootstrap goes through link_dotfiles" "yes" \
    "$(mentions "$repo/script/bootstrap" 'link_dotfiles')"
check "system/install.sh goes through link_dotfiles" "yes" \
    "$(mentions "$repo/system/install.sh" 'link_dotfiles')"
check "bootstrap has no symlink loop of its own" "no" \
    "$(mentions "$repo/script/bootstrap" "symlink' -type f")"
check "system/install.sh has none either" "no" \
    "$(mentions "$repo/system/install.sh" "symlink' -type f")"

rm -rf "$DOTFILES_ROOT" "$dest" "$fake_home" "$fake_config"

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
