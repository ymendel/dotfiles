npm_installed () {
    npm list --location=global | grep --quiet " ${1}@"
}

npm_install_with_check () {
    npm_installed $1 || npm install --location=global $1
}
