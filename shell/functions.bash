echoc() {
  echo -e "${1}$2${ResetColor}" | sed 's/\\\]//g'  | sed 's/\\\[//g'
}

# inspired by http://beckism.com/2009/02/better_bash_prompt/#comment-19411
divider()
{
    echo -ne "\033[1;38;43m"
    for ((x=1; x <= $COLUMNS; x++))
    do
        echo -ne "="
    done
    echo -e  "\033[0m"
}
