npm_installed () {
    npm list --global | grep --quiet " ${1}@"
}

npm_install_with_check () {
    npm_installed $1 || npm install --global $1
}
