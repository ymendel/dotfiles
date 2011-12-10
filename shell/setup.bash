export PS1="\h:\w\$(git_display) \u\$ "

export EDITOR=vi

export LC_CTYPE=en_us.UTF-8

shopt -s histappend
export HISTSIZE=10000
export HISTFILESIZE=${HISTSIZE}
export HISTCONTROL="ignoredups"
export HISTIGNORE="&:l[salh]:[bf]g:exit"

for f in aliases functions bash_completion_base
do
  test -r ~/.$f && source ~/.$f
done
