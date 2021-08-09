#!/bin/bash

if test $(which brew)
then
    echo "  Homebrew already installed"
else
    if [ "$(uname -s)" == "Darwin" ]
    then
        echo "  Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi

exit 0
