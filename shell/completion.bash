# Homebrew installs formula completions into etc/bash_completion.d (the legacy
# "compat" directory) and bash-completion sources every file in it at startup —
# at the time of this writing, that's 84 files, taking ~2.5s. Bad.
# The "new" goodness is the lazy loading from its completions/ directories —
# looked up and loaded by command name, as you ask for them (by pressing <tab>).
#
# Don't need the eager loading, don't want the eager loading. To turn it off, though,
# you need to point the compat directory at a nonexistent path — because an empty
# value reads as "not set" and bash-completion just uses the built-in default. Yay.
#
# Then give the lazy loader somewhere else to look. In this case, two specific places.
# Note that `BASH_COMPLETION_USER_DIR` takes paths that are not used directly themselves,
# but they contain `completions/` directories that are used. That's a design, sure.
# Note also that ordering matters. First match wins.
#
#   1. shell/bash-completion — holding a one-line file for each Homebrew completion
#      the lazy loader can't use as it stands: a filename that isn't the command it
#      completes, or a file that's found and simply doesn't work (cf. heroku).
#      This is named first specifically to allow overriding things (again, cf. heroku).
#   2. another directory that symlinks to Homebrew's compat dir — handled by install.sh
#
# Most of the work is done by #2 there, since the vast majority of commands do match and
# have completion that works, so the Homebrew-installed completion does _fine_.
# It's also necessary, since while bash-completion ships a large fallback set of its own,
# that's for standard Unix tools and not Homebrew's formulae.

export BASH_COMPLETION_COMPAT_DIR=/nonexistent-so-nothing-loads-eagerly
export BASH_COMPLETION_USER_DIR="$DOTFILES_HOME/shell/bash-completion:$HOME/.local/share/homebrew-completions"

bash_completion="$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

[[ -r "$bash_completion" ]] && source "$bash_completion"

unset bash_completion
