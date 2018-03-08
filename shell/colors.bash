#!/usr/bin/env bash
#
# source this file to get color definitions
#
# taken from magicmonty/bash-git-prompt (where it's called 'prompt-colors.sh')
# and tweaked heavily because I want more possibilities,
# and I'm into tput over the escape sequences

define_color_names() {

  ColorNames=( Black Red Green Yellow Blue Magenta Cyan White )

  _def_colors() {
    local x=0
    while (( x < 8 )) ; do
      local colorname=${ColorNames[x]}
      local colorcode=x
      _def_color_fg $colorname $x
      _def_color_bg $colorname $x
      (( x++ ))
    done
  }

  _def_color_fg() {
    local def="$1=\$(tput setaf $2)"
    eval "$def"

    local def="$1Fg=$(tput setaf $2)"
    eval "$def"
  }

  _def_color_bg() {
    local def="$1Bg=$(tput setab $2)"
    eval "$def"
  }

  _def_colors

  Bold=$(tput bold)
  Dim=$(tput dim)
  Under=$(tput smul)
  Rev=$(tput rev)
  Blink=$(tput blink)
  Invis=$(tput invis)

  ResetColor=$(tput sgr0)

}

# do the color definitions only once
if [[ ${#ColorNames[*]} = 0 || -z "$IntenseBlack" || -z "$ResetColor" ]]; then
  define_color_names
fi
