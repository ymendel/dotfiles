bash_completion="$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

[[ -r "$bash_completion" ]] && source "$bash_completion"

unset bash_completion
