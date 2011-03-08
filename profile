export PATH="$PATH:~/scripts"

export PS1="\h:\w\$(git_display) \u\$ "
export PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}\007"'

export EDITOR=vi

export LC_CTYPE=en_us.UTF-8

shopt -s histappend
export HISTSIZE=10000
export HISTFILESIZE=${HISTSIZE}
export HISTCONTROL="ignoredups"
export HISTIGNORE="&:ls:[bf]g:exit"

for f in aliases functions
do
  test -f ~/.$f && source ~/.$f
done

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
