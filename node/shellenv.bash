# HOMEBREW_PREFIX comes from homebrew/shellenv.bash, which sorts ahead of this
# one in the sourcing loop. Nothing here calls brew: `brew list nvm` on its own
# was two seconds of shell startup, and every path it went out to confirm is
# static. The -s test is the presence check, and an unset prefix simply fails it.
nvm_prefix="$HOMEBREW_PREFIX/opt/nvm"

if [[ -s "$nvm_prefix/nvm.sh" ]]
then
  unset npm_config_prefix
  export NVM_DIR="$HOME/.nvm"
  source "$nvm_prefix/nvm.sh"
  [[ -s "$nvm_prefix/etc/bash_completion.d/nvm" ]] && source "$nvm_prefix/etc/bash_completion.d/nvm"
fi

unset nvm_prefix
