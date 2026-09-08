# a little belt-and-suspenders action, making sure the path includes
# the homebrew stuff. `brew shellenv` should already handle this
# but don't let `/sbin` come first
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/sbin" ]]
then
    export PATH="$HOMEBREW_PREFIX/sbin:$PATH"
fi

for d in $(find -H "$DOTFILES_HOME" -name bin -type d)
do
    PATH="$PATH:$d"
done

export PATH="$PATH:$HOME/bin:$HOME/scripts:$HOME/.local/bin"
