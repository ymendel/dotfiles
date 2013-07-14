# say what?
alias voices="ls /System/Library/Speech/Voices/ | sed s/.SpeechVoice// | sed s/\\\\/// | grep -v Compact"
alias random_voice="voices | xargs echo | ruby -wne 'voices = \$_.split.collect { |voice|  voice.gsub(/([a-z])([A-Z])/, %q{\1 \2}) }; print voices[rand(voices.length)];'"
