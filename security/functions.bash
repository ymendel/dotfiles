get_op_password_to_paste () {
    op item get "$1" --fields label=password | pbcopy
}
