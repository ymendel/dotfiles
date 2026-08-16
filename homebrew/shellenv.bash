# `brew shellenv` exports HOMEBREW_PREFIX, so everything sourced after this can
# stop shelling out to brew just to learn a path. Finding brew in order to run
# it is the catch: the prefix is architecture-dependent, and only /usr/local/bin
# is on the default macOS PATH (see /etc/paths), which is exactly why an Apple
# Silicon install prints this eval for you to paste into your profile. There is
# no prefix-agnostic bootstrap to defer to.
#
# So take brew from PATH when it's already there, and fall back to the two known
# prefixes when it isn't.
for homebrew in brew /opt/homebrew/bin/brew /usr/local/bin/brew
do
  command -v "$homebrew" > /dev/null || continue
  eval "$("$homebrew" shellenv)"
  break
done

unset homebrew
