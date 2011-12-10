export PATH="$PATH:$DOTFILES_HOME/bin"

for d in $DOTFILES_HOME/**/bin
do
    export PATH="$PATH:$d"
done

export PATH="$PATH:~/bin:~/scripts"
