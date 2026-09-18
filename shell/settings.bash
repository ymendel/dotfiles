export BASH_SILENCE_DEPRECATION_WARNING=1

# -F = "quit if one screen"
# -R = "raw control chars" (allow color sequences, mostly)
# -X = "no init" (skip the alternate screen, so output stays put on quit)
export LESS=-FRX
