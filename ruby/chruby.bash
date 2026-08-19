# chruby loads eagerly, unlike nvm
# It _cannot_ be shimmed. auto.sh's DEBUG trap is what switches ruby on cd,
# and (for example) an editor that spawns a login shell to capture an environment
# for a language server (how will that ever be a concern?) never runs a command
# for a lazy shim to intercept. It would read whatever ruby was on PATH first.
__chruby_share="$HOMEBREW_PREFIX/share/chruby"

if [[ -s "$__chruby_share/chruby.sh" ]]
then
  source "$__chruby_share/chruby.sh"

  # auto.sh installs its DEBUG trap unconditionally, clobbering whatever was
  # there. Thankfully, shell/prompt.bash does its own careful dance to add
  # its trap to what already exists.
  source "$__chruby_share/auto.sh"
  chruby_auto
fi

unset __chruby_share
