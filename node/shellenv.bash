# HOMEBREW_PREFIX comes from homebrew/shellenv.bash, which sorts ahead of this
# one in the sourcing loop. Nothing here calls brew: `brew list nvm` on its own
# was two seconds of shell startup, and every path it went out to confirm is
# static. The -s test is the presence check, and an unset prefix simply fails it.
__nvm_prefix="$HOMEBREW_PREFIX/opt/nvm"

if [[ -s "$__nvm_prefix/nvm.sh" ]]
then
  unset npm_config_prefix
  export NVM_DIR="$HOME/.nvm"

  # Sourcing nvm.sh costs the better part of a second, most of it resolving the
  # `default` alias, and a shell that never touches node pays that for nothing.
  # So stand in shims that load nvm for real on first use and then get out of
  # the way. __nvm_prefix has to outlive this file for them to find nvm.sh.
  #
  # node, npm and npx are shimmed alongside nvm itself because they have to be.
  # `default` resolves to a real version here, so without them the first `node`
  # in a shell would be Homebrew's rather than the one nvm means to give you.
  #
  # What this costs. nvm's own completion isn't there until nvm has been run
  # once in that shell. And nvm's bin directory is no longer on PATH from the
  # start, so anything that doesn't inherit these functions — a script, a
  # Makefile, an editor's task runner — gets Homebrew's node instead of the
  # default version. Run something through a shim first if that matters.
  __load_nvm () {
    unset -f nvm node npm npx __load_nvm
    source "$__nvm_prefix/nvm.sh"
    [[ -s "$__nvm_prefix/etc/bash_completion.d/nvm" ]] && source "$__nvm_prefix/etc/bash_completion.d/nvm"
    unset __nvm_prefix
  }

  nvm  () { __load_nvm; nvm  "$@"; }
  node () { __load_nvm; node "$@"; }
  npm  () { __load_nvm; npm  "$@"; }
  npx  () { __load_nvm; npx  "$@"; }
else
  unset __nvm_prefix
fi
