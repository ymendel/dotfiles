# FLAC stuff
alias find_nonflac="find . \( \! -name '*.flac' -and \! -type d \) -print"
alias convert_flacs="find . -name '*.flac' -exec flac2mp3 {} \;"
alias remove_flacs="find . -name '*.flac' -exec rm {} \;"
