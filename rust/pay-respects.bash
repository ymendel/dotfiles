[[ -f $HOME/.cargo/env ]] && source $HOME/.cargo/env

# this gives a warning when in a non-interactive shell
# so check if $- (the shell's option flags) contains i (for interactive)
[[ $- == *i* ]] && eval "$(pay-respects bash --alias crap)"
