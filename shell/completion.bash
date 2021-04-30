if [ -f /usr/local/etc/bash_completion ]; then
  . /usr/local/etc/bash_completion
fi
export PATH="/opt/homebrew/bin:$PATH"
if [ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
  . /opt/homebrew/etc/profile.d/bash_completion.sh
fi
