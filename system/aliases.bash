# some commands need defaults
alias ls="ls -qF"
alias bc="bc -ql"
alias mvim="mvim -p"

# ls shorthand
alias la="ls -a"
alias ll="ls -l"
alias lh="ls -lh"
alias lal="ls -al"

# canonical present dir
alias cpd='cd `pwd -P`'

# new tabs and terms
alias tab=new_tab
alias new=new_term

# finding processes
alias find_process="ps auxwwww | grep -v grep | grep "
alias find_ps=find_process
alias fps=find_process

alias where="command -v"
alias so=sudo

alias remove_ds_stores="find . -name ".DS_Store" -depth -exec rm {} \;"

alias ql='qlmanage -p > /dev/null 2>&1'

alias boxon="boxen --no-pull --enable-services"
alias boxoff="boxen --no-pull --disable-services"

alias shouty="cltr [[:lower:]] [[:upper:]]"
# TODO: make this work without perl? just sed/awk/tr or whatever? am I that good?
alias alty="perl -le '\$_ = join(\" \", @ARGV); s/(.)(.)?/\U\1\L\2/g; print'"

alias flagmoji="cltr 'A-Za-z' '🇦-🇿🇦-🇿'"

alias fix_camera="sudo killall VDCAssistant"
