# inspired by http://beckism.com/2009/02/better_bash_prompt/#comment-19411
divider()
{
    echo -n "${Bold}${YellowBg}"
    for ((x=1; x <= $COLUMNS; x++))
    do
        echo -n "="
    done
    echo $ResetColor
}
