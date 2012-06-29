export PATH="/usr/local/sbin:$PATH"

for d in $(find $DOTFILES_HOME -name bin -type d)
do
    PATH="$PATH:$d"
done

export PATH="$PATH:~/bin:~/scripts"
