# say what?
alias voices="say -v ? | ruby -wne 'print \$_.sub(/\s+en_US.*$/, %q{}).tr(%q{ }, %q{_})'"
alias random_voice="voices | xargs echo | ruby -wne 'voices = \$_.split.collect { |voice|  voice.tr(%q{_}, %q{ }) }; print voices[rand(voices.length)];'"
alias random_say="say -v \`random_voice\`"
