# helpful functions
info () {
    printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

prompt () {
    printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

warn () {
    printf "\r\033[2K  [\033[0;33mWARN\033[0m] $1\n"
}

fail () {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
    echo ''
    exit
}
