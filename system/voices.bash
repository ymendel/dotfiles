# say what?
alias voices="say -v ?"
alias voice_names="voices | awk '{print \$1}'"
alias random_voice="voice_names | sort -R | head -1"
alias random_say="voice=\`random_voice\`; echo \"using \$voice\"; say -v \$voice"
