# some commands need defaults
alias ls="ls -qF"
alias bc="bc -ql"
alias mvim="mvim -p"

# ls shorthand
alias la="ls -a"
alias ll="ls -l"
alias lh="ls -lh"
alias lal="ls -al"

# new tabs and terms
alias tab=new_tab
alias new=new_term

# finding processes
alias find_process="ps auxwwww | grep -v grep | grep "
alias find_ps=find_process
alias fps=find_process

alias where="type -ap"
alias so=sudo

alias remove_ds_stores="find . -name ".DS_Store" -depth -exec rm {} \;"

alias ql='qlmanage -p > /dev/null 2>&1'

alias boxon="boxen --no-pull --enable-services"
alias boxoff="boxen --no-pull --disable-services"

alias shouty="tr [[:lower:]] [[:upper:]]"

alias flagmoji="tr 'A-Z' '🇦-🇿'"

alias fix_camera="sudo killall VDCAssistant"
