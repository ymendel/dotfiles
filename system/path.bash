# a little belt-and-suspenders action, making sure the path includes
# the homebrew stuff. `brew shellenv` should already handle this
# but don't let `/sbin` come first (which is what would happen if
# HOMEBREW_PREFIX were unset)
if [[ -n "$HOMEBREW_PREFIX" ]]
then
    path_prepend "$HOMEBREW_PREFIX/sbin"
fi

for d in $(find -H "$DOTFILES_HOME" -name bin -type d)
do
    path_append "$d"
done

path_append "$HOME/bin"
path_append "$HOME/scripts"
path_append "$HOME/.local/bin"
