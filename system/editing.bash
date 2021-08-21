export EDITOR=vim

mvim_directory_server()
{
  if [ $# == 0 ]
  then
    mvim
  elif [ ${1:0:2} = '--' ]
  then
      if [ $1 = '--git-root' ]
      then
        mvim --servername $(basename $(git top)) --remote-tab-silent "${@:2}" &>/dev/null
      elif [ $1 = '--pwd' ]
      then
        mvim --servername $(basename $(pwd)) --remote-tab-silent "${@:2}" &>/dev/null
      else
          echo 'what does that mean?'
      fi
  else
    mvim --servername $(basename $(pwd)) --remote-tab-silent "$@" &>/dev/null
  fi
}

alias v=mvim_directory_server
alias vg="mvim_directory_server --git-root"
alias vp="mvim_directory_server --pwd"
